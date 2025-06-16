//
//  PhotoItem.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 13/06/25.
//

import SwiftUI
import Photos
import PhotosUI

// MARK: - Photo Model
struct PhotoItem: Identifiable, Sendable, Equatable {
    let id = UUID()
    let asset: PHAsset
    let image: UIImage?
}

// MARK: - Album Model
struct AlbumItem: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let assetCollection: PHAssetCollection?
    let count: Int
    
    static func == (lhs: AlbumItem, rhs: AlbumItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Photo Manager Actor
@MainActor
class PhotoManager: ObservableObject {
    @Published var photos: [PhotoItem] = []
    @Published var albums: [AlbumItem] = []
    @Published var selectedAlbum: AlbumItem?
    @Published var isLoading = false
    @Published var hasPermission = false
    
    private let imageLoader = ImageLoader()
    
    init() {
        Task {
            await checkPermission()
        }
    }
    
    func checkPermission() async {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            hasPermission = true
            await loadAlbums()
        case .denied, .restricted:
            hasPermission = false
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            hasPermission = status == .authorized || status == .limited
            if hasPermission {
                await loadAlbums()
            }
        @unknown default:
            hasPermission = false
        }
    }
    
    func loadAlbums() async {
        albums.removeAll()
        
        // Add "Recent" album (all photos)
        let allPhotosCount = await fetchAssetCount(for: .image)
        let recentAlbum = AlbumItem(title: "Recent", assetCollection: nil, count: allPhotosCount)
        albums.append(recentAlbum)
        
        // Fetch albums
        let fetchedAlbums = await fetchAlbums()
        albums.append(contentsOf: fetchedAlbums)
        
        // Set default to "Recent"
        selectedAlbum = recentAlbum
        await loadPhotos(from: recentAlbum)
    }
    
    private func fetchAssetCount(for mediaType: PHAssetMediaType) async -> Int {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            continuation.resume(returning: assets.count)
        }
    }
    
    private func fetchAlbums() async -> [AlbumItem] {
        return await withCheckedContinuation { continuation in
            var albumItems: [AlbumItem] = []
            
            // Fetch user albums
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            userAlbums.enumerateObjects { collection, _, _ in
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                if assets.count > 0 {
                    let album = AlbumItem(
                        title: collection.localizedTitle ?? "Unknown",
                        assetCollection: collection,
                        count: assets.count
                    )
                    albumItems.append(album)
                }
            }
            
            // Fetch smart albums
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            smartAlbums.enumerateObjects { collection, _, _ in
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                if assets.count > 0 && collection.assetCollectionSubtype != .smartAlbumAllHidden {
                    let album = AlbumItem(
                        title: collection.localizedTitle ?? "Unknown",
                        assetCollection: collection,
                        count: assets.count
                    )
                    albumItems.append(album)
                }
            }
            
            continuation.resume(returning: albumItems)
        }
    }
    
    func loadPhotos(from album: AlbumItem) async {
        isLoading = true
        photos.removeAll()
        
        let assets = await fetchAssets(from: album)
        let photoItems = await imageLoader.loadImages(for: assets)
        
        // Sort by creation date (newest first)
        photos = photoItems.sorted {
            ($0.asset.creationDate ?? Date.distantPast) > ($1.asset.creationDate ?? Date.distantPast)
        }
        
        isLoading = false
    }
    
    private func fetchAssets(from album: AlbumItem) async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets: PHFetchResult<PHAsset>
            if let collection = album.assetCollection {
                assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            } else {
                // "Recent" album - fetch all photos
                assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            }
            
            var assetArray: [PHAsset] = []
            assets.enumerateObjects { asset, _, _ in
                assetArray.append(asset)
            }
            
            continuation.resume(returning: assetArray)
        }
    }
    
    func selectAlbum(_ album: AlbumItem) {
        selectedAlbum = album
        Task {
            await loadPhotos(from: album)
        }
    }
}

// MARK: - Image Loader Actor
actor ImageLoader {
    private let imageManager = PHCachingImageManager()
    private let imageRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        return options
    }()
    
    func loadImages(for assets: [PHAsset]) async -> [PhotoItem] {
        await withTaskGroup(of: PhotoItem?.self, returning: [PhotoItem].self) { group in
            // Add tasks for each asset
            for asset in assets {
                group.addTask {
                    await self.loadSingleImage(for: asset)
                }
            }
            
            // Collect results
            var photoItems: [PhotoItem] = []
            for await photoItem in group {
                if let photoItem = photoItem {
                    photoItems.append(photoItem)
                }
            }
            
            return photoItems
        }
    }
    
    private func loadSingleImage(for asset: PHAsset) async -> PhotoItem? {
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: imageRequestOptions
            ) { image, info in
                // Only resume once, and only when we have the final result
                guard !hasResumed else { return }
                
                // Check if this is the final result (not a progressive update)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = (info?[PHImageErrorKey] as? Error) != nil
                
                // Resume only for final result or if there's an error/cancellation
                if !isDegraded || isCancelled || hasError {
                    hasResumed = true
                    let photoItem = PhotoItem(asset: asset, image: image)
                    continuation.resume(returning: photoItem)
                }
            }
        }
    }
    
    func loadFullSizeImage(for asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                // Only resume once, and only when we have the final result
                guard !hasResumed else { return }
                
                // Check if this is the final result (not a progressive update)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = (info?[PHImageErrorKey] as? Error) != nil
                
                // Resume only for final result or if there's an error/cancellation
                if !isDegraded || isCancelled || hasError {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
// MARK: - Main Content View
struct PhotoGalleryView: View {
    @StateObject private var photoManager = PhotoManager()
    @State private var selectedItems: [PhotoItem] = []
    @Environment(\.dismiss) private var dismiss
    
    // Callback to pass selected items back
    let onPhotosSelected: ([PhotoItem]) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(onPhotosSelected: @escaping ([PhotoItem]) -> Void) {
        self.onPhotosSelected = onPhotosSelected
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if photoManager.hasPermission {
                    // Album Selector
                    albumSelector
                    
                    // Photo Grid
                    photoGrid
                } else {
                    permissionView
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onPhotosSelected(selectedItems)
                        dismiss()
                    }
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
    }
    
    private var albumSelector: some View {
        HStack {
            Spacer()
            Menu {
                ForEach(photoManager.albums) { album in
                    Button(action: {
                        photoManager.selectAlbum(album)
                        // Clear selection when changing albums
                        selectedItems.removeAll()
                    }) {
                        HStack {
                            Text(album.title)
                            Spacer()
                            Text("(\(album.count))")
                                .foregroundColor(.secondary)
                            if album.id == photoManager.selectedAlbum?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(photoManager.selectedAlbum?.title ?? "Select Album")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var photoGrid: some View {
        ScrollView {
            if photoManager.isLoading {
                ProgressView("Loading photos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photoManager.photos) { photo in
                        SelectablePhotoCell(
                            photo: photo,
                            isSelected: selectedItems.contains { $0.id == photo.id },
                            onToggleSelection: { toggleSelection(for: photo) }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Photo Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please allow access to your photos to view and manage your photo library.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func toggleSelection(for photo: PhotoItem) {
        if let index = selectedItems.firstIndex(where: { $0.id == photo.id }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(photo)
        }
    }
}

// MARK: - Selectable Photo Cell
struct SelectablePhotoCell: View {
    let photo: PhotoItem
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    var body: some View {
        ZStack {
            Group {
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
            .frame(width: (UIScreen.main.bounds.width - 6) / 3, height: (UIScreen.main.bounds.width - 6) / 3)
            .clipped()
            .overlay(
                // Selection overlay - stays within clipped bounds
                Rectangle()
                    .fill(navy.opacity(isSelected ? 0.3 : 0))
                    .overlay(
                        // Selection indicator
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                    
                                    if isSelected {
                                        Circle()
                                            .fill(navy)
                                            .frame(width: 20, height: 20)
                                        
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 12, weight: .bold))
                                    } else {
                                        Circle()
                                            .stroke(Color.gray, lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    )
            )
            .overlay(
                // Border when selected - inside the clipped area
                Rectangle()
                    .strokeBorder(navy, lineWidth: isSelected ? 3 : 0)
            )
        }
        .contentShape(Rectangle()) // Ensures tap area is limited to the cell bounds
        .onTapGesture {
            onToggleSelection()
        }
    }
}


//
//  MainViewModel.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import Combine
import SwiftUI
import CoreData
import UniformTypeIdentifiers
import UIKit // for UIPasteboard

// MARK: - Main View Model
class MainViewModel: ObservableObject {
    @Published var fileItems: [FileItem] = []
    @Published var searchedItems: [FileItem] = []
    @Published var bookmarkedItems: [FileItem] = []
    @Published var recentItems: [FileItem] = []
    @Published var searchText: String = ""
    @Published var selectedSortType: SortType = .dateNewest
    @Published var selectedFileType: FileType? = nil
    @Published var isLoading: Bool = false
    @Published var showingDocumentPicker: Bool = false
    @Published var showingDirectoryPicker: Bool = false
    @Published var isImporting: Bool = false
    @Published var importProgress: Double = 0.0
    @Published var selectedDirectory: URL?
    @Published var availableDirectories: [URL] = []
    @Published var pendingURLToEnhance: URL? = nil

    private let persistenceController = PersistenceController.shared
    private let fileManagerService = FileManagerService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        recoverMissingFiles()
        
        setupSearchAndSortObservers()
        setupFileManagerObservers()
        fetchFilesFromCoreData()
    }

    
    func isFileAlreadySaved(named name: String) -> Bool {
        // Check Core Data if any file entity exists with this name
        let fetchRequest: NSFetchRequest<FileItem> = FileItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        do {
            let count = try persistenceController.context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking if file exists: \(error)")
            return false
        }
    }

    private func setupSearchAndSortObservers() {
        Publishers.CombineLatest3($searchText, $selectedSortType, $selectedFileType)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.filterAndSortFiles()
            }
            .store(in: &cancellables)
    }

    private func setupFileManagerObservers() {
        // Observe file manager changes
        fileManagerService.$availableFiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchFilesFromCoreData()
            }
            .store(in: &cancellables)

        // Observe import state
        fileManagerService.$isImporting
            .receive(on: DispatchQueue.main)
            .assign(to: \.isImporting, on: self)
            .store(in: &cancellables)

        // Observe selected directory changes
        $selectedDirectory
            .sink { [weak self] directory in
                if let directory = directory {
                    self?.loadFilesFromDirectory(directory)
                }
            }
            .store(in: &cancellables)
    }

    private func loadAvailableDirectories() {
        availableDirectories = fileManagerService.getAvailableDirectories()

        // Set default directory if none selected
        if selectedDirectory == nil && !availableDirectories.isEmpty {
            selectedDirectory = availableDirectories.first
        }
    }

    func selectDirectory(_ directory: URL) {
        selectedDirectory = directory
        UserDefaults.standard.set(directory.path, forKey: "selectedDirectory")
    }

    private func loadFilesFromDirectory(_ directory: URL) {
        isLoading = true

        // Update file manager to scan selected directory
        fileManagerService.setSelectedDirectory(directory)
        fileManagerService.refreshFiles()

        // Fetch from Core Data
        fetchFilesFromCoreData()

        isLoading = false
    }

    func loadFiles() {
        guard let directory = selectedDirectory else {
            loadAvailableDirectories()
            return
        }

        loadFilesFromDirectory(directory)
    }

     func fetchFilesFromCoreData() {
        fileItems = []
        let context = persistenceController.context

        // Fetch files from selected directory only
        let allFilesRequest: NSFetchRequest<FileItem> = FileItem.fetchRequest()

        fileItems = (try? context.fetch(allFilesRequest)) ?? []
        fetchBookmarkedFiles()
    }

    func fetchBookmarkedFiles(){
        bookmarkedItems = fileItems.filter({ $0.isBookmarked == true })
    }

    func filterAndSortFiles(fileType : FilterType? = nil) {
        var filteredFiles = fileItems

        // Apply search filter
        if !searchText.isEmpty {
            filteredFiles = filteredFiles.filter { $0.name!.localizedCaseInsensitiveContains(searchText) }
        }

        // Apply sorting
        switch fileType {
        case .fileSize:
            filteredFiles.sort { $0.fileSize < $1.fileSize }

        case .name:
            filteredFiles.sort { $0.name!.localizedCompare($1.name!) == .orderedAscending }
        case .lastViewed:
            filteredFiles.sort { $0.modifiedDate! > $1.modifiedDate! }

        case .lastModified:
            filteredFiles.sort { $0.modifiedDate! > $1.modifiedDate! }

        case .fromNewtoOld:
            filteredFiles.sort { $0.modifiedDate! > $1.modifiedDate! }

        case .fromOldtoNew:
            filteredFiles.sort { $0.modifiedDate! < $1.modifiedDate! }
        case .none: break

        }

        fileItems = filteredFiles
    }

    // MARK: - Directory Operations
    func presentDirectoryPicker() {
        showingDirectoryPicker = true
    }

    func addCustomDirectory(_ url: URL) {
        if !availableDirectories.contains(url) {
            availableDirectories.append(url)
            // Save to UserDefaults for persistence
            let paths = availableDirectories.map { $0.path }
            UserDefaults.standard.set(paths, forKey: "availableDirectories")
        }
        selectDirectory(url)
    }

    // MARK: - File Import Operations
    func presentDocumentPicker() {
        showingDocumentPicker = true
    }

    func importFiles(from urls: [URL]) {
        guard let selectedDirectory = selectedDirectory else { return }
        for url in urls {
            if (url.scheme == "http" || url.scheme == "https") && url.pathExtension.lowercased() == "pdf" {
                // Remote PDF shortcut: copy URL and trigger enhancement
                UIPasteboard.general.string = url.absoluteString
                pendingURLToEnhance = url
                // UI should observe pendingURLToEnhance and present enhancement flow
                continue
            } else {
                fileManagerService.importFiles(from: [url], to: selectedDirectory)
            }
        }
    }
    
    /// Call this from UI after enhancement is done, to save the PDF locally.
    func completeEnhancementAndSave(url: URL) {
        guard let selectedDirectory = selectedDirectory else { return }
        fileManagerService.importFiles(from: [url], to: selectedDirectory)
        pendingURLToEnhance = nil
    }
    // UI should observe `pendingURLToEnhance` using `.onChange` or similar and present EnhanceDPDFView before saving.

    // MARK: - File Operations
    func toggleBookmark(for fileItem: FileItem) {
        fileItem.isBookmarked.toggle()
        if fileItem.isBookmarked {
            let bookmark = BookmarkModel(context: persistenceController.context)
            bookmark.id = UUID()
            bookmark.fileItem = fileItem
            bookmark.bookmarkedDate = Date()
        }
        persistenceController.save()
        fetchFilesFromCoreData()
    }

    func markAsRecentlyAccessed(_ fileItem: FileItem) {
        fileItem.isRecentlyAccessed = true
        fileItem.lastAccessedDate = Date()
        persistenceController.save()
        fetchFilesFromCoreData()
    }

    func renameFile(_ fileItem: FileItem, newName: String) {
        let oldURL = URL(fileURLWithPath: fileItem.path!)
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(oldURL.pathExtension)

        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            fileItem.name = newName
            fileItem.path = newURL.path
            persistenceController.save()
            loadFiles()
        } catch {
            print("Error renaming file: \(error)")
        }
    }

    func deleteFile(_ fileItem: FileItem) {
        let url = URL(fileURLWithPath: fileItem.path!)

        // Use enhanced file manager service for deletion
//        if fileManagerService.deleteFile(at: url) {
            persistenceController.context.delete(fileItem)
            persistenceController.save()
            // No need to call loadFiles() as FileManagerService will trigger refresh
//        }
    }

    func refreshFiles() {
        guard let selectedDirectory = selectedDirectory else { return }
        fileManagerService.setSelectedDirectory(selectedDirectory)
        fileManagerService.refreshFiles()
    }

    // MARK: - File Information Helpers
    func getFormattedFileSize(for fileItem: FileItem) -> String {
        return fileManagerService.formatFileSize(fileItem.fileSize)
    }

    func isFileAccessible(_ fileItem: FileItem) -> Bool {
        let url = URL(fileURLWithPath: fileItem.path!)
        return fileManagerService.isFileAccessible(at: url)
    }

    // MARK: - Statistics
    var totalFilesCount: Int {
        return fileItems.count
    }

    var totalFileSize: Int64 {
        return fileItems.reduce(0) { $0 + $1.fileSize }
    }

    var formattedTotalSize: String {
        return fileManagerService.formatFileSize(totalFileSize)
    }

    var selectedDirectoryName: String {
        return selectedDirectory?.lastPathComponent ?? "No Directory Selected"
    }

    // MARK: - File Type Statistics
    func getFileCountByType(_ fileType: FileType) -> Int {
        return fileItems.filter { $0.fileTypeEnum == fileType }.count
    }

    func getFileSizeByType(_ fileType: FileType) -> Int64 {
        return fileItems
            .filter { $0.fileTypeEnum == fileType }
            .reduce(0) { $0 + $1.fileSize }
    }


//    func saveInCoreData(fileURLs : [URL]) {
//        let context = PersistenceController.shared.context
//        // Add new files
//        for url in fileURLs {
//            let path = url.path
//            let fileItem = FileItem(context: context)
//            fileItem.id = UUID()
//            fileItem.name = url.deletingPathExtension().lastPathComponent
//            fileItem.path = path
//            fileItem.directoryPath = path//selectedDirectory?.path ?? ""
//            fileItem.fileTypeEnum = FileManagerService.shared.getFileType(for: url)
//            fileItem.fileSize = FileManagerService.shared.getFileSize(for: url)
//            fileItem.createdDate = Date()
//            fileItem.modifiedDate = FileManagerService.shared.getModificationDate(for: url)
//            fileItem.isBookmarked = false
//            fileItem.isRecentlyAccessed = false
//        }
//        
//        PersistenceController.shared.save()
//        
//        fetchFilesFromCoreData()
//    }

}

// MARK: - Directory Picker for MainViewModel
struct DirectoryPicker: UIViewControllerRepresentable {
    @ObservedObject var mainViewModel: MainViewModel
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DirectoryPicker

        init(_ parent: DirectoryPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let directoryURL = urls.first {
                parent.mainViewModel.addCustomDirectory(directoryURL)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Document Picker Wrapper for MainViewModel
struct MainDocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var mainViewModel: MainViewModel
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes = FileType.allCases.flatMap { $0.utTypes }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: MainDocumentPicker

        init(_ parent: MainDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.mainViewModel.importFiles(from: urls)
            parent.presentationMode.wrappedValue.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}



extension MainViewModel {

    func saveInCoreData(fileURLs: [URL]) {
        let context = PersistenceController.shared.context

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfDirectory = documentsDirectory.appendingPathComponent("PDFs")

        // Create PDFs directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: pdfDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("Failed to create PDFs directory: \(error)")
            return
        }

        for fileURL in fileURLs {
            processFileForImport(fileURL: fileURL,
                                 destinationDirectory: pdfDirectory,
                                 context: context)
        }

        PersistenceController.shared.save()
        fetchFilesFromCoreData()
    }

    private func processFileForImport(fileURL: URL, destinationDirectory: URL, context: NSManagedObjectContext) {
        let fileName = fileURL.lastPathComponent
        let destinationURL = destinationDirectory.appendingPathComponent(fileName)

        // Start accessing security-scoped resource
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Check iCloud metadata
            let resourceValues = try fileURL.resourceValues(forKeys: [
                .isUbiquitousItemKey,
                .ubiquitousItemDownloadingStatusKey,
                .fileSizeKey,
                .contentModificationDateKey
            ])

            let isUbiquitous = resourceValues.isUbiquitousItem ?? false
            let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
            let isDownloaded = (downloadStatus == .current)
            let fileSize = resourceValues.fileSize ?? 0
            let modificationDate = resourceValues.contentModificationDate ?? Date()

            if isUbiquitous && !isDownloaded {
                print("Downloading iCloud file: \(fileName)")
                try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)

                waitForiCloudDownload(fileURL: fileURL) { [weak self] success in
                    if success {
                        self?.copyFileToLocal(from: fileURL,
                                              to: destinationURL,
                                              fileName: fileName,
                                              fileSize: fileSize,
                                              modificationDate: modificationDate,
                                              context: context)
                    } else {
                        print("Failed to download iCloud file: \(fileName)")
                    }
                }
            } else {
                copyFileToLocal(from: fileURL,
                                to: destinationURL,
                                fileName: fileName,
                                fileSize: fileSize,
                                modificationDate: modificationDate,
                                context: context)
            }

        } catch {
            print("Error processing file \(fileName): \(error)")
            copyFileToLocal(from: fileURL,
                            to: destinationURL,
                            fileName: fileName,
                            fileSize: 0,
                            modificationDate: Date(),
                            context: context)
        }
    }

    private func waitForiCloudDownload(fileURL: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var attempts = 0
            let maxAttempts = 60 // ~30 seconds timeout

            while attempts < maxAttempts {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                    let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                    let isDownloaded = (downloadStatus == .current)

                    if isDownloaded {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                        return
                    }
                } catch {
                    print("Error checking download status: \(error)")
                }

                attempts += 1
                Thread.sleep(forTimeInterval: 0.5)
            }

            // Timeout
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

    private func copyFileToLocal(from sourceURL: URL,
                                 to destinationURL: URL,
                                 fileName: String,
                                 fileSize: Int,
                                 modificationDate: Date,
                                 context: NSManagedObjectContext) {
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Copy file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            // Save in Core Data
            let fileItem = FileItem(context: context)
            fileItem.name = fileName
            fileItem.path = destinationURL.absoluteString // ✅ Store full URL as String
            fileItem.fileType = determineFileType(from: fileName)
            fileItem.createdDate = Date()
            fileItem.modifiedDate = modificationDate
            fileItem.fileSize = Int64(fileSize)
            fileItem.isBookmarked = false
            fileItem.directoryPath = sourceURL.absoluteString

            print("Successfully copied and saved: \(fileName)")

        } catch {
            print("Failed to copy file \(fileName): \(error)")
        }
    }
}


func determineFileType(from fileName: String) -> String {
    let fileExtension = (fileName as NSString).pathExtension.lowercased()

    switch fileExtension {
    case "pdf":
        return "pdf"
    case "doc", "docx":
        return "word"
    case "xls", "xlsx":
        return "excel"
    case "ppt", "pptx":
        return "powerpoint"
    default:
        return "pdf" // Default fallback
    }
}

extension FileRowView {

    private func enhancedValidateAndShowPreview() {
        if let storedPath = file.path,
           let fileURL = URL(string: storedPath),
           FileManager.default.fileExists(atPath: fileURL.path) {
            previewError = nil
    //        navigateToPreview = true
            return
        }

//        fallbackFileLookup()
    }

}


extension MainViewModel{
    
    /// Recovers missing files by checking if files at the stored path exist,
    /// if not but the original file exists, copies it back to the expected location.
    func recoverMissingFiles() {
        var context = persistenceController.context
        let fileManager = FileManager.default
        let fetchRequest: NSFetchRequest<FileItem> = FileItem.fetchRequest()
        
        do {
            let fileItems = try context.fetch(fetchRequest)
            var changesMade = false
            
            for fileItem in fileItems {
                guard let storedPath = fileItem.path,
                      let originalPath = fileItem.directoryPath else {
                    continue
                }
                
                let checkedStoredPath: String
                if storedPath.starts(with: "file://") {
                    checkedStoredPath = URL(string: storedPath)?.path ?? storedPath
                } else {
                    checkedStoredPath = storedPath
                }
                
                let checkedOriginalPath: String
                if originalPath.starts(with: "file://") {
                    checkedOriginalPath = URL(string: originalPath)?.path ?? originalPath
                } else {
                    checkedOriginalPath = originalPath
                }
                
                // Check if file exists at stored (local) path
                if !fileManager.fileExists(atPath: checkedStoredPath) {
                    print("File missing at expected path: \(checkedStoredPath)")
                    // If original file exists, attempt to copy it back to stored path
                    if fileManager.fileExists(atPath: checkedOriginalPath) {
                        let originalURL = URL(fileURLWithPath: checkedOriginalPath)
                        let storedURL = URL(fileURLWithPath: checkedStoredPath)
                        
                        // If the target path is occupied (rare since missing check), find a unique filename
                        var finalDestinationURL = storedURL
                        var counter = 1
                        while fileManager.fileExists(atPath: finalDestinationURL.path) {
                            let newName = "\(storedURL.deletingPathExtension().lastPathComponent)_\(counter).\(storedURL.pathExtension)"
                            finalDestinationURL = storedURL.deletingLastPathComponent().appendingPathComponent(newName)
                            counter += 1
                        }
                        
                        do {
                            try fileManager.copyItem(at: originalURL, to: finalDestinationURL)
                            print("Recovered file by copying from original path to \(finalDestinationURL.path)")
                            
                            // Update fileItem.path if the copied location is different from the stored path
                            if finalDestinationURL.path != checkedStoredPath {
                                fileItem.path = finalDestinationURL.path
                                changesMade = true
                                print("Updated FileItem.path to new recovered location: \(finalDestinationURL.path)")
                            }
                        } catch {
                            print("Failed to recover missing file from original path: \(error)")
                        }
                    } else {
                        // Original file does not exist locally, check if it's an iCloud file and attempt to download
                        let originalURL = URL(fileURLWithPath: checkedOriginalPath)
                        do {
                            let resourceValues = try originalURL.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
                            let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                            let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                            let isDownloaded = (downloadStatus == .current)
                            
                            if isUbiquitous && !isDownloaded {
                                print("Original file at path \(checkedOriginalPath) is an iCloud file and not downloaded. Starting download...")
                                try fileManager.startDownloadingUbiquitousItem(at: originalURL)
                                
                                var attempts = 0
                                let maxAttempts = 20 // 5 seconds timeout (0.25s * 20)
                                var fileNowExists = false
                                while attempts < maxAttempts {
                                    if fileManager.fileExists(atPath: checkedOriginalPath) {
                                        fileNowExists = true
                                        break
                                    }
                                    Thread.sleep(forTimeInterval: 0.25)
                                    attempts += 1
                                }
                                
                                if fileNowExists {
                                    print("Successfully downloaded iCloud file at original path: \(checkedOriginalPath)")
                                    // After download, try copying again
                                    let storedURL = URL(fileURLWithPath: checkedStoredPath)
                                    var finalDestinationURL = storedURL
                                    var counter = 1
                                    while fileManager.fileExists(atPath: finalDestinationURL.path) {
                                        let newName = "\(storedURL.deletingPathExtension().lastPathComponent)_\(counter).\(storedURL.pathExtension)"
                                        finalDestinationURL = storedURL.deletingLastPathComponent().appendingPathComponent(newName)
                                        counter += 1
                                    }

                                    do {
                                        try fileManager.copyItem(at: originalURL, to: finalDestinationURL)
                                        print("Recovered file by copying from original path to \(finalDestinationURL.path) after iCloud download")

                                        if finalDestinationURL.path != checkedStoredPath {
                                            fileItem.path = finalDestinationURL.path
                                            changesMade = true
                                            print("Updated FileItem.path to new recovered location: \(finalDestinationURL.path)")
                                        }
                                    } catch {
                                        print("Failed to recover missing file from original path after iCloud download: \(error)")
                                    }
                                } else {
                                    print("Failed to download iCloud file within timeout for path: \(checkedOriginalPath)")
                                }
                            } else {
                                print("Original file also missing at path: \(checkedOriginalPath), cannot recover.")
                                persistenceController.context.delete(fileItem)
                                changesMade = true
                                print("Deleted FileItem from Core Data because file could not be recovered: \(checkedOriginalPath)")
                            }
                        } catch {
                            print("Error checking iCloud status of original file at \(checkedOriginalPath): \(error)")
                            print("Original file also missing at path: \(checkedOriginalPath), cannot recover.")
                            persistenceController.context.delete(fileItem)
                            changesMade = true
                            print("Deleted FileItem from Core Data because file could not be recovered: \(checkedOriginalPath)")
                        }
                    }
                }
            }
            
            // Save context if any changes were made
            if changesMade {
                do {
                    try context.save()
                    print("Core Data context saved after recovering missing files.")
                } catch {
                    print("Failed to save Core Data context after recovery: \(error)")
                }
            } else {
                print("No missing files needed recovery.")
            }
            
        } catch {
            print("Failed to fetch FileItems for recovery: \(error)")
        }
    }
}


extension MainViewModel {
    func refreshFileItems() {
        // Trigger a refresh of the fileItems array
        // This will cause the view to update
        objectWillChange.send()
        
        // If you need to reload from Core Data, you can do:
        // fetchFileItems() // or whatever method you use to load data
        
        // Or if you're using @FetchRequest, you might need to trigger a manual refresh
        // by updating the fetch request predicate or sort descriptors
    }
}

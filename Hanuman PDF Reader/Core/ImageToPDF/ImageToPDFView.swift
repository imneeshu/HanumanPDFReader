//
//  ImageToPDFView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//
//
//  ImageToPDFView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

struct ImageToPDFView: View {
    @State private var selectedImages: [UIImage] = []
    @Binding  var selectedItems: [PhotoItem]
    @State private var showingImagePicker = false
    @State private var showingRenameSheet = false
    @State private var showingSaveShareView = false
    @State private var showingPDFViewer = false
    @State private var pdfFileName: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm"
        return "Images_\(formatter.string(from: Date()))"
    }()
    @State private var createdPDFURL: URL?
    @State private var isProcessing = false
    @State private var draggedItem: UIImage?
    @State private var isReorderMode = false // New state for reorder mode
    
    var body: some View {
            VStack {
                AdBanner("ca-app-pub-3940256099942544/2934735716")
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(Color.clear)
                if selectedImages.isEmpty {
                    addPageCell
                        .padding()
                } else {
                    // Images preview
                    VStack {
                        // Header with count and reorder button
                        HStack {
                            // Pan/Reorder button with gradient styling
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isReorderMode.toggle()
                                }
                            }) {
                                Image(systemName: isReorderMode ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle")
                                    .font(.system(size: 32, weight: .medium))
                                    .overlay(
                                        navy
                                        .mask(
                                            Image(systemName: isReorderMode ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle")
                                                .font(.system(size: 32, weight: .medium))
                                        )
                                    )
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 44, height: 44)
                                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .scaleEffect(isReorderMode ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isReorderMode)
                            
                            Spacer().frame(width: 16)
                            
                            Text("\(selectedImages.count) Image\(selectedImages.count == 1 ? "" : "s") Selected")
                                .font(.headline)
                            
                            Spacer()
                            
                            if isReorderMode {
                                Text("Tap to reorder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Images grid with Add Page cell
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 0) {
                                
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    imageCell(image: image, index: index)
                                        .padding()
                                }
                                
                                if !isReorderMode {
                                    addPageCell
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        // Convert button (hidden in reorder mode)
                        if !isReorderMode {
                            Button(action: {
                                showingRenameSheet = true
                            }) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "doc.fill")
                                    }
                                    Text(isProcessing ? "Converting..." : "Convert to PDF")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(convertButtonBackground)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Image to PDF")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItems) { items in
                Task {
                    await loadImages(from: items)
                }
            }
            .onAppear{
                Task {
                    await loadImages(from: selectedItems)
                }
            }
        
            .sheet(isPresented: $showingRenameSheet) {
                RenameSheet(
                    pdfName: $pdfFileName,
                    onCancel: { showingRenameSheet = false },
                    onDone: {
                        Task {
                            await convertToPDF()
                        }
                    }
                )
                .presentationDetents([.fraction(0.30)])
            }
        
            .sheet(isPresented: $showingSaveShareView) {
                SaveShareSheetContent(
                    pdfURL: createdPDFURL!,
                    fileName: pdfFileName,
                    onViewPDF: {
                        showingSaveShareView = false
                        showingPDFViewer = true
                    }
                )
            }
        
            .fullScreenCover(isPresented: $showingPDFViewer) {
                if let pdfURL = createdPDFURL {
//                    PDFViewerView(pdfURL: pdfURL, fileName: pdfFileName)
                }
            }
    }
    
    
    // Grid configuration
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Add Page Cell
    private var addPageCell: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .overlay(
                        navy
                        .mask(
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                        )
                    )
                
                Text("Add Page")
                    .font(.headline)
                    .overlay(
                        navy
                        .mask(
                            Text("Add Page")
                                .font(.headline)
                        )
                    )
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(addPageBackground)
            .cornerRadius(10)
        }
    }
    
    // Add Page Background
    private var addPageBackground: some View {
        ZStack {
            navy.opacity(0.05)
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    navy,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        }
    }
    
    // Image Cell
    private func imageCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            imageView(image: image)
            
            // Show remove button only when not in reorder mode
            if !isReorderMode {
                removeButton(index: index)
            }
            
            // Show reorder indicator when in reorder mode
            if isReorderMode {
                VStack {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 22, weight: .medium))
                            .overlay(
//                                LinearGradient(
//                                    gradient: Gradient(colors: [
//                                        .black,
//                                        Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
//                                        Color(red: 0.6, green: 0.4, blue: 0.9),
//                                        Color(red: 0.8, green: 0.3, blue: 0.8)
//                                    ]),
//                                    startPoint: .topLeading,
//                                    endPoint: .bottomTrailing
//                                )
                                navy
                                .mask(
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 22, weight: .medium))
                                )
                            )
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                            )
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
//                    LinearGradient(
//                        gradient: Gradient(colors: isReorderMode ? [
//                            Color(red: 0.6, green: 0.4, blue: 0.9),
//                            Color(red: 0.8, green: 0.3, blue: 0.8)
//                        ] : [Color.gray, Color.clear]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
                    navy,
                    lineWidth: isReorderMode ? 3 : 0
                )
        )
        .scaleEffect(isReorderMode && selectedImageForReorder == image ? 0.95 : 1.0)
        .onDrag {
            draggedItem = image
            return NSItemProvider(object: String(index) as NSString)
        }
        .onDrop(of: [UTType.text], delegate: DropViewDelegate(
            destinationItem: image,
            images: $selectedImages,
            draggedItem: $draggedItem
        ))
        .onTapGesture {
            // Handle tap for reordering in reorder mode
            if isReorderMode {
                handleImageTapForReorder(image: image, index: index)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isReorderMode)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedImageForReorder)
    }
    
    // Image View
    private func imageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .clipped()
            .cornerRadius(12) // Slightly smaller radius for inner image
            .opacity(draggedItem == image ? 0.5 : 1.0) // Fixed: This will reset properly
            .scaleEffect(draggedItem == image ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: draggedItem)
            .padding(4) // Add padding inside the outer border
    }
    
    // Remove Button
    private func removeButton(index: Int) -> some View {
        Button(action: {
            removeImage(at: index)
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .background(removeButtonBackground)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(8)
    }
    
    // Remove image function
    private func removeImage(at index: Int) {
        withAnimation(.easeOut(duration: 0.3)) {
            selectedImages.remove(at: index)
        }
    }
    
    // Handle image tap for reordering
    @State private var selectedImageForReorder: UIImage?
    @State private var selectedIndexForReorder: Int?
    
    private func handleImageTapForReorder(image: UIImage, index: Int) {
        if let selectedImage = selectedImageForReorder,
           let selectedIndex = selectedIndexForReorder,
           selectedImage != image {
            
            // Perform the reorder
            withAnimation(.easeInOut(duration: 0.3)) {
                let draggedImage = selectedImages[selectedIndex]
                selectedImages.remove(at: selectedIndex)
                selectedImages.insert(draggedImage, at: index)
            }
            
            // Reset selection
            selectedImageForReorder = nil
            selectedIndexForReorder = nil
        } else {
            // Select this image for reordering
            selectedImageForReorder = image
            selectedIndexForReorder = index
        }
    }
    
    // Remove Button Background
    private var removeButtonBackground: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 28, height: 28)
    }
    
    // Computed property for button background
    private var convertButtonBackground: some View {
        Group {
            if isProcessing {
                Color.gray
            } else {
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color.black,
//                        Color(red: 0.18, green: 0.0, blue: 0.21),
//                        Color(red: 0.6, green: 0.4, blue: 0.9),
//                        Color(red: 0.8, green: 0.3, blue: 0.8)
//                    ]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
                navy
            }
        }
    }
    
    private func loadImages(from items: [PhotoItem]) async {
        var newImages: [UIImage] = []
        
        for item in items {
            if let image = item.image {
                newImages.append(image)
            }
        }
        
        await MainActor.run {
            selectedImages.append(contentsOf: newImages)
            selectedItems = [] // Clear selection
        }
    }
    
    private func convertToPDF() async {
        await MainActor.run {
            isProcessing = true
        }
        
        let pdfDocument = PDFDocument()
        
        for (index, image) in selectedImages.enumerated() {
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        
        // Save PDF to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent("\(pdfFileName).pdf")
        
        pdfDocument.write(to: pdfURL)
        
        await MainActor.run {
            createdPDFURL = pdfURL
            isProcessing = false
            showingRenameSheet = false
            showingSaveShareView = true
        }
    }
}

// iOS 15 compatible date formatting extension
extension Date {
    func formatted(_ format: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm"
        return formatter.string(from: self)
    }
}

// DateFormatStyle placeholder for iOS 15 compatibility
struct DateFormatStyle {
    func year() -> DateFormatStyle { return self }
    func month() -> DateFormatStyle { return self }
    func day() -> DateFormatStyle { return self }
    func hour() -> DateFormatStyle { return self }
    func minute() -> DateFormatStyle { return self }
    
    static let dateTime = DateFormatStyle()
}

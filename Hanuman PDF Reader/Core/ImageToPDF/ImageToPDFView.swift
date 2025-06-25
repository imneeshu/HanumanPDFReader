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
    @Environment(\.presentationMode) var presentationMode
    let onClosePDF: () -> Void
    @State private var pdfFileName: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm"
        return "Images_\(formatter.string(from: Date()))"
    }()
    @State private var createdPDFURL: URL?
    @State private var isProcessing = false
    @State private var draggedItem: UIImage?
    @State private var isReorderMode = false // New state for reorder mode
    @EnvironmentObject var interstitialAdManager : InterstitialAdManager
    @State var showAd : Bool = false
    @State var bannerIsLoaded : Bool = false
    
    var body: some View {
            VStack {
                if !PremiumStatus.shared.isPremiumPurchased{
                    AdBanner(adUnitID: bannerAd, bannerIsLoaded: $bannerIsLoaded)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .background(Color.clear)
                }
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
                        
                        let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    imageCell(image: image, index: index)
                                }

                                if !isReorderMode {
                                    addPageCell
                                        .frame(width :  UIScreen.main.bounds.width / 2 - 32,height: 170)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        
                        Spacer()
                        
                        // Convert button (hidden in reorder mode)
                        if !isReorderMode {
                            Button(action: {
                                showAd = true
                                //showingRenameSheet = true
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
                    .padding(
                        .top,
                        (
                            bannerIsLoaded
                        ) ? 20 : 0
                    )
                }
            }
            .navigationTitle("Image_to_PDF")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingImagePicker) {
                PhotoGalleryView { selectedItems in
                    for item in selectedItems{
                        self.selectedItems.append(item)
                    }
                }
            }
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
            .onChange(of: showAd, perform: { newValue in
                if interstitialAdManager.isLoaded && !PremiumStatus.shared.isPremiumPurchased {
                    interstitialAdManager.showAd()
                }
                else{
                    showingRenameSheet = true
                }
            })
        
            .onChange(of: interstitialAdManager.isPresenting, perform: { newValue in
                if newValue == false{
                    showingRenameSheet = true
                    interstitialAdManager.refreshAd()
                }
            })
        
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
        
            .fullScreenCover(isPresented: $showingSaveShareView) {
                SaveShareSheetContent(
                    pdfURL: createdPDFURL!,
                    fileName: pdfFileName,
                    onViewPDF: {
                        showingSaveShareView = false
                        showingPDFViewer = true
                    },
                    onClosePDF:{
                        onClosePDF()
                        presentationMode.wrappedValue.dismiss()
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
                
                Text("Add_Page")
                    .font(.headline)
                    .overlay(
                        navy
                        .mask(
                            Text("Add_Page")
                                .font(.headline)
                        )
                    )
            }
            .frame(height: 170)
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
    
    private func imageCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // Main image view
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width / 2 - 32, height: 170)
                .clipped()
                .cornerRadius(16)

            // Show remove (❌) button only when not in reorder mode
            if !isReorderMode {
                Button(action: {
                    selectedImages.remove(at: index)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(6)
            }

            // Reorder mode indicator (3-line icon)
            if isReorderMode {
                VStack {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 22, weight: .medium))
                            .overlay(
                                navy.mask(
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
        let pdfURL = documentsPath.appendingPathComponent("PDFs/\(pdfFileName).pdf")
        
        pdfDocument.write(to: pdfURL)
        savePDF(
            destinationURL: pdfURL,
            fileName: pdfFileName,
            modificationDate: Date()
        )
        
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





struct DocumentExportView: UIViewControllerRepresentable {
    let pdfURL: URL
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = PDFExportViewController(pdfURL: pdfURL) {
            // Convert DismissAction to closure
            dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class PDFExportViewController: UIViewController, UIDocumentPickerDelegate {
    
    private var pdfURL: URL?
    private var dismissAction: (() -> Void)?

    init(pdfURL: URL, dismiss: @escaping () -> Void) {
        self.pdfURL = pdfURL
        self.dismissAction = dismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Make the view transparent so it doesn't show
        view.backgroundColor = UIColor.clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Small delay to ensure the view controller is fully presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.exportPDFIfAvailable()
        }
    }

    private func exportPDFIfAvailable() {
        guard let pdfURL = pdfURL else {
            print("❌ No PDF URL provided.")
            dismissAction?()
            return
        }

        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            print("❌ File does not exist at path: \(pdfURL.path)")
            dismissAction?()
            return
        }

        let documentPicker = UIDocumentPickerViewController(forExporting: [pdfURL], asCopy: true)
        documentPicker.delegate = self
        documentPicker.shouldShowFileExtensions = true
        documentPicker.modalPresentationStyle = .fullScreen
        
        present(documentPicker, animated: true)
    }

    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("✅ PDF copied/exported to: \(urls.first?.absoluteString ?? "Unknown")")
        controller.dismiss(animated: true) {
            self.dismissAction?()
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("❌ Export cancelled by user.")
        controller.dismiss(animated: true) {
            self.dismissAction?()
        }
    }
}

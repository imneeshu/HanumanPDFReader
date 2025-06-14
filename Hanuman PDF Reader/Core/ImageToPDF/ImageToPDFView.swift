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
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingRenameSheet = false
    @State private var showingSaveShareView = false
    @State private var showingPDFViewer = false
    @State private var pdfFileName = "Images_\(Date().formatted(.dateTime.year().month().day().hour().minute()))"
    @State private var createdPDFURL: URL?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedImages.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("No Images Selected")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Select images from your gallery to convert them into a PDF")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("Select Images")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                } else {
                    // Images preview
                    VStack {
                        // Header with count and add button
                        HStack {
                            Text("\(selectedImages.count) Image\(selectedImages.count == 1 ? "" : "s") Selected")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Images grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipped()
                                            .cornerRadius(10)
                                        
                                        // Remove button
                                        Button(action: {
                                            selectedImages.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.red)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                        }
                                        .padding(5)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        // Convert button
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
                            .background(isProcessing ? Color.gray : Color.green)
                            .cornerRadius(10)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Image to PDF")
            .navigationBarTitleDisplayMode(.large)
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedItems,
                maxSelectionCount: 20,
                matching: .images
            )
            .onChange(of: selectedItems) { items in
                Task {
                    await loadImages(from: items)
                }
            }
            .sheet(isPresented: $showingRenameSheet) {
                RenameFileSheet(
                    fileName: $pdfFileName,
                    onSave: {
                        Task {
                            await convertToPDF()
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSaveShareView) {
                if let pdfURL = createdPDFURL {
                    SaveShareView(
                        pdfURL: pdfURL, 
                        fileName: pdfFileName,
                        onViewPDF: {
                            showingSaveShareView = false
                            showingPDFViewer = true
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showingPDFViewer) {
                if let pdfURL = createdPDFURL {
                    PDFViewerView(pdfURL: pdfURL, fileName: pdfFileName)
                }
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var newImages: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
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

struct RenameFileSheet: View {
    @Binding var fileName: String
    let onSave: () -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Name your PDF file")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top)
                
                TextField("Enter file name", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Save PDF")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create PDF") {
                    onSave()
                }
                .fontWeight(.semibold)
                .disabled(fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

struct SaveShareView: View {
    let pdfURL: URL
    let fileName: String
    let onViewPDF: () -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("PDF Created Successfully!")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Your PDF '\(fileName).pdf' has been saved to your device")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    // View PDF button
                    Button(action: onViewPDF) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("View PDF")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    // Share button
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share PDF")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("PDF Saved")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [pdfURL])
        }
    }
}

// MARK: - PDF Viewer
struct PDFViewerView: View {
    let pdfURL: URL
    let fileName: String
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            PDFKitRepresentedView(url: pdfURL)
                .navigationTitle(fileName)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [pdfURL])
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure PDF view
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Enable user interactions
        pdfView.usePageViewController(true, withViewOptions: nil)
        
        // Load PDF document
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update if needed
    }
}

//struct ShareSheet: UIViewControllerRepresentable {
//    let items: [Any]
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
//        return activityViewController
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}

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

#Preview {
    ImageToPDFView()
}

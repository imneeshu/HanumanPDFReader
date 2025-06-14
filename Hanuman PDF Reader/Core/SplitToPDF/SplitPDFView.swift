//
//  SplitPDFView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct SplitPDFView: View {
    @State private var selectedPDF: URL?
    @State private var pdfDocument: PDFDocument?
    @State private var selectedPages: Set<Int> = []
    @State private var showingDocumentPicker = false
    @State private var showingPreview = false
    @State private var previewDocument: PDFDocument?
    @State private var showingRenameAlert = false
    @State private var newFileName = ""
    @State private var showingShareSheet = false
    @State private var splitPDFURL: URL?
    @State private var showingSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            if pdfDocument == nil {
                // Initial state - show document picker button
                VStack(spacing: 20) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Select a PDF to Split")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Choose pages to extract into a new PDF")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Choose PDF File")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                // PDF loaded - show pages and controls
                VStack(spacing: 15) {
                    // Header with file info and controls
                    HStack {
                        VStack(alignment: .leading) {
                            Text(selectedPDF?.lastPathComponent ?? "PDF Document")
                                .font(.headline)
                                .lineLimit(1)
                            Text("\(pdfDocument?.pageCount ?? 0) pages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Select All") {
                            if selectedPages.count == pdfDocument?.pageCount {
                                selectedPages.removeAll()
                            } else {
                                selectedPages = Set(0..<(pdfDocument?.pageCount ?? 0))
                            }
                        }
                        .font(.caption)
                        
                        Button("New PDF") {
                            showingDocumentPicker = true
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    
                    // Selected pages info
                    if !selectedPages.isEmpty {
                        Text("\(selectedPages.count) page\(selectedPages.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                    }
                    
                    // Pages collection view
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 120), spacing: 10)
                        ], spacing: 15) {
                            ForEach(0..<(pdfDocument?.pageCount ?? 0), id: \.self) { pageIndex in
                                PDFPageView(
                                    page: pdfDocument?.page(at: pageIndex),
                                    pageNumber: pageIndex + 1,
                                    isSelected: selectedPages.contains(pageIndex)
                                ) {
                                    togglePageSelection(pageIndex)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Split button
                    if !selectedPages.isEmpty {
                        Button(action: {
                            splitPDF()
                        }) {
                            HStack {
                                Image(systemName: "scissors")
                                Text("Split Selected Pages")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Split PDF")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentSelection(result)
        }
        .alert("Rename PDF", isPresented: $showingRenameAlert) {
            TextField("File name", text: $newFileName)
            Button("Cancel", role: .cancel) { }
            Button("Save & Share") {
                saveFinalPDF(fileName: newFileName)
            }
        } message: {
            Text("Enter a name for your split PDF")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = splitPDFURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("PDF has been split and saved successfully!")
        }
        .sheet(isPresented: $showingPreview) {
            PDFPreviewView(
                document: previewDocument,
                fileName: $newFileName,
                onSave: { finalFileName in
                    saveFinalPDF(fileName: finalFileName)
                },
                onCancel: {
                    showingPreview = false
                    previewDocument = nil
                }
            )
        }
    }
    
    private func togglePageSelection(_ pageIndex: Int) {
        if selectedPages.contains(pageIndex) {
            selectedPages.remove(pageIndex)
        } else {
            selectedPages.insert(pageIndex)
        }
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedPDF = url
            loadPDF(from: url)
        case .failure(let error):
            print("Error selecting document: \(error)")
        }
    }
    
    private func loadPDF(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        pdfDocument = PDFDocument(url: url)
        selectedPages.removeAll()
    }
    
    private func splitPDF() {
        guard let document = pdfDocument,
              !selectedPages.isEmpty else { return }
        
        // Create preview document
        let newDocument = PDFDocument()
        let sortedPages = selectedPages.sorted()
        
        for (index, pageIndex) in sortedPages.enumerated() {
            if let page = document.page(at: pageIndex) {
                newDocument.insert(page, at: index)
            }
        }
        
        previewDocument = newDocument
        newFileName = "Split_\(selectedPDF?.deletingPathExtension().lastPathComponent ?? "Document")"
        showingPreview = true
    }
    
    private func saveFinalPDF(fileName: String) {
        guard let document = previewDocument else { return }
        
        // Save to Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finalFileName = fileName.hasSuffix(".pdf") ? fileName : "\(fileName).pdf"
        let fileURL = documentsPath.appendingPathComponent(finalFileName)
        
        if document.write(to: fileURL) {
            splitPDFURL = fileURL
            showingPreview = false
            showingShareSheet = true
            showingSuccessAlert = true
            
            // Reset for next use
            previewDocument = nil
        }
    }
}

struct PDFPageView: View {
    let page: PDFPage?
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(radius: 2)
                
                if let page = page {
                    PDFPageThumbnailView(page: page)
                        .aspectRatio(0.7, contentMode: .fit)
                        .cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(0.7, contentMode: .fit)
                }
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                        )
                }
                
                // Selection indicator
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            Text("Page \(pageNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct PDFPageThumbnailView: UIViewRepresentable {
    let page: PDFPage
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        let thumbnail = page.thumbnail(of: CGSize(width: 200, height: 280), for: .cropBox)
        uiView.image = thumbnail
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PDFPreviewView: View {
    let document: PDFDocument?
    @Binding var fileName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @State private var currentPageIndex = 0
    @State private var showingRenameAlert = false
    @State private var tempFileName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if let document = document {
                    // PDF Preview
                    VStack {
                        // Page indicator
                        HStack {
                            Button(action: {
                                if currentPageIndex > 0 {
                                    currentPageIndex -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(currentPageIndex > 0 ? .blue : .gray)
                            }
                            .disabled(currentPageIndex <= 0)
                            
                            Spacer()
                            
                            Text("Page \(currentPageIndex + 1) of \(document.pageCount)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                if currentPageIndex < document.pageCount - 1 {
                                    currentPageIndex += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(currentPageIndex < document.pageCount - 1 ? .blue : .gray)
                            }
                            .disabled(currentPageIndex >= document.pageCount - 1)
                        }
                        .padding()
                        
                        // PDF Page Display
                        if let page = document.page(at: currentPageIndex) {
                            PDFPagePreviewView(page: page)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    // File info and controls
                    VStack(spacing: 15) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Split PDF Preview")
                                    .font(.headline)
                                Text("\(document.pageCount) pages selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        HStack(spacing: 15) {
                            Button("Cancel") {
                                onCancel()
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            
                            Button("Save & Share") {
                                tempFileName = fileName
                                showingRenameAlert = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                } else {
                    Text("No preview available")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Save PDF", isPresented: $showingRenameAlert) {
                TextField("File name", text: $tempFileName)
                Button("Cancel", role: .cancel) { }
                Button("Save & Share") {
                    onSave(tempFileName)
                }
            } message: {
                Text("Enter a name for your PDF file")
            }
        }
    }
}

struct PDFPagePreviewView: UIViewRepresentable {
    let page: PDFPage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let imageView = UIImageView()
        
        // Generate high-quality thumbnail
        let thumbnail = page.thumbnail(of: CGSize(width: 600, height: 800), for: .cropBox)
        imageView.image = thumbnail
        imageView.contentMode = .scaleAspectFit
        
        scrollView.addSubview(imageView)
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        guard let imageView = uiView.subviews.first as? UIImageView else { return }
        
        let thumbnail = page.thumbnail(of: CGSize(width: 600, height: 800), for: .cropBox)
        imageView.image = thumbnail
        
        // Set frame
        imageView.frame = CGRect(origin: .zero, size: thumbnail.size)
        uiView.contentSize = thumbnail.size
        
        // Center the image
        let boundsSize = uiView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.subviews.first else { return }
            
            let boundsSize = scrollView.bounds.size
            var frameToCenter = imageView.frame
            
            if frameToCenter.width < boundsSize.width {
                frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2
            } else {
                frameToCenter.origin.x = 0
            }
            
            if frameToCenter.height < boundsSize.height {
                frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2
            } else {
                frameToCenter.origin.y = 0
            }
            
            imageView.frame = frameToCenter
        }
    }
}

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
    @Binding var pdfDocument: PDFDocument?
    @Binding var selectedPages: Set<Int>
    @State private var showingRenameAlert = false
    @State private var newFileName = ""
    @State private var showingShareSheet = false
    @State private var splitPDFURL: URL?
    
    @State private var splitPDFPreviewDocument: PDFDocument?
    @State private var showSplitPreviewSheet = false
    @State var showShareView : Bool = false

    var body: some View {
        VStack(spacing: 10) {
            AdBanner("ca-app-pub-3940256099942544/2934735716")
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background(Color.clear)
            
            if pdfDocument?.pageCount ?? 0 > 0 {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 20) {
                        ForEach(0..<(pdfDocument!.pageCount), id: \.self) { pageIndex in
                            PDFPageView(
                                page: pdfDocument!.page(at: pageIndex),
                                pageNumber: pageIndex + 1,
                                isSelected: selectedPages.contains(pageIndex)
                            ) {
                                togglePageSelection(pageIndex)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top , 20)
                
                Button(action: {
                    newFileName = "Split_\(selectedPDF?.deletingPathExtension().lastPathComponent ?? "Document")"
                    saveSplitPDF(fileName: newFileName)
                    showingRenameAlert = true
                }) {
                    HStack {
                        Image(systemName: "scissors")
                        Text("Split_PDF")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedPages.isEmpty ? AnyView(Color.gray) : AnyView(navy))
                    .cornerRadius(10)
                }
                .disabled(selectedPages.isEmpty)
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Split_PDF")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareView) {
            if let url = splitPDFURL {
                SaveShareSheetContent(
                    pdfURL: url,
                    fileName: newFileName,
                    onViewPDF: {
                        // Add any additional navigation logic here if needed
                    }
                )
            }
        }
        .sheet(isPresented: $showingRenameAlert) {
            RenameSheet(
                pdfName: $newFileName,
                onCancel: { showingRenameAlert = false },
                onDone: {
                    Task {
                        if let splitPDFURL = splitPDFURL {
                            let newURL = await renamePDF(originalURL: splitPDFURL, newName: newFileName)
                            self.splitPDFURL = newURL
                            showingRenameAlert = false
                            showShareView = true
                            
                        }
                    }
                }
            )
            .presentationDetents([.fraction(0.30)])
        }
    }

    private func togglePageSelection(_ pageIndex: Int) {
        if selectedPages.contains(pageIndex) {
            selectedPages.remove(pageIndex)
        } else {
            selectedPages.insert(pageIndex)
        }
    }
    
    private func prepareSplitPreview(for fileName: String) {
        guard let pdfDocument = pdfDocument, !selectedPages.isEmpty else { return }
        let splitDocument = PDFDocument()
        let sortedPages = selectedPages.sorted()
        for (newIndex, pageIndex) in sortedPages.enumerated() {
            if let page = pdfDocument.page(at: pageIndex) {
                splitDocument.insert(page, at: newIndex)
            }
        }
        splitPDFPreviewDocument = splitDocument
        showSplitPreviewSheet = true
    }

    private func saveSplitPDF(fileName: String) {
        guard let pdfDocument = pdfDocument, !selectedPages.isEmpty else { return }
        let splitDocument = PDFDocument()
        let sortedPages = selectedPages.sorted()
        for (newIndex, pageIndex) in sortedPages.enumerated() {
            if let page = pdfDocument.page(at: pageIndex) {
                splitDocument.insert(page, at: newIndex)
            }
        }
        // Save to Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let safeFileName = fileName.hasSuffix(".pdf") ? fileName : "\(fileName).pdf"
        let fileURL = documentsPath.appendingPathComponent(safeFileName)
        if splitDocument.write(to: fileURL) {
            splitPDFURL = fileURL
            showingShareSheet = true
            // Reset selection for next use only after successful save
            selectedPages.removeAll()
            selectedPDF = nil
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
        let thumbnail = page.thumbnail(of: CGSize(width: 160, height: 280), for: .cropBox)
        uiView.image = thumbnail
    }
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
                                Text("Split_PDF_Preview")
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
                Text("Enter_a_name_for_your_PDF_file")
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

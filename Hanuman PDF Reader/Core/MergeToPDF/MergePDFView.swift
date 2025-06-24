//
//  MergePDFView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - PDF Merge Error
enum PDFMergeError: LocalizedError {
    case noFilesToMerge
    case invalidFile
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .noFilesToMerge:
            return "No files selected for merging"
        case .invalidFile:
            return "One or more files are invalid or corrupted"
        case .writeFailed:
            return "Failed to write merged PDF file"
        }
    }
}

struct MergePDFView: View {
    @State private var selectedPDFs: [URL] = []
    @State private var showingDocumentPicker = false
    @State private var showingPreview = false
    @State private var showingRename = false
    @State private var showingFinalScreen = false
    @State private var mergedPDFURL: URL?
    @State private var finalPDFName = "Merged_PDF"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @Binding var selectedFileItems: [FileItem]
    @Binding var  listFlow : ListFlow
    
    var body: some View {
                // PDF Selection Cards
                VStack(spacing: 15) {
                    List {
                        ForEach(selectedFileItems, id: \.objectID) { file in
                            FileRowViewForSelection(
                                file: file,
                                isSelected: false,
                                onSelectionToggle: {
                                    //                                    toggleSelection(for: file)
                                    //                                    viewModel.markAsRecentlyAccessed(file)
                                }, listFlow: $listFlow
                            )
                            .cornerRadius(10)
                        }
                    }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    // Preview Button
                    Button(action: {
                        showingPreview = true
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Preview_PDFs")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .disabled(selectedPDFs.count < 2)
                    
                    // Merge Button
                    Button(action: {
                        mergePDFs()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.on.doc")
                            }
                            Text(isLoading ? "Merging..." : "Merge PDFs")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedPDFs.count == 2 ? Color.green : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(selectedPDFs.count < 2 || isLoading)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Merge PDF")
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerMe(selectedPDFs: $selectedPDFs)
            }
            .sheet(isPresented: $showingPreview) {
                PDFPreviewViewMe(
                    pdfURLs: selectedPDFs,
                    onReplace: { index in
                        selectPDF(index: index)
                    }
                )
            }
            .sheet(isPresented: $showingRename) {
                if let mergedURL = mergedPDFURL {
                    RenameView(
                        pdfURL: mergedURL,
                        initialName: finalPDFName,
                        onComplete: { finalURL in
                            mergedPDFURL = finalURL
                            showingFinalScreen = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showingFinalScreen) {
                if let finalURL = mergedPDFURL {
                    FinalScreenView(pdfURL: finalURL)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
    }
    
    private func selectPDF(index: Int) {
        showingDocumentPicker = true
    }
    
    private func mergePDFs() {
        guard selectedPDFs.count == 2 else { return }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let mergedURL = try PDFMerger.mergePDFs(selectedPDFs)
                
                DispatchQueue.main.async {
                    self.mergedPDFURL = mergedURL
                    self.isLoading = false
                    self.showingRename = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct PDFSelectionCard: View {
    let title: String
    let pdfURL: URL?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: pdfURL != nil ? "doc.fill" : "doc.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(pdfURL != nil ? .red : .gray)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let pdfURL = pdfURL {
                            Text(pdfURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Tap_to_select_PDF")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if pdfURL != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DocumentPickerMe: UIViewControllerRepresentable {
    @Binding var selectedPDFs: [URL]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerMe
        
        init(_ parent: DocumentPickerMe) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            if parent.selectedPDFs.count < 2 {
                parent.selectedPDFs.append(url)
            } else {
                parent.selectedPDFs[1] = url
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PDFPreviewViewMe: View {
    let pdfURLs: [URL]
    let onReplace: (Int) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(pdfURLs.enumerated()), id: \.offset) { index, url in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("PDF \(index + 1): \(url.lastPathComponent)")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    onReplace(index)
                                }) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            PDFPreviewThumbnail(pdfURL: url)
                                .frame(height: 200)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct PDFPreviewThumbnail: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct RenameView: View {
    let pdfURL: URL
    @State var fileName: String
    let onComplete: (URL) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var isRenaming = false
    
    init(pdfURL: URL, initialName: String, onComplete: @escaping (URL) -> Void) {
        self.pdfURL = pdfURL
        self._fileName = State(initialValue: initialName)
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Name Your Merged PDF")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("File_Name")
                        .font(.headline)
                    
                    TextField("Enter PDF name", text: $fileName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            renamePDF()
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: renamePDF) {
                    HStack {
                        if isRenaming {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text(isRenaming ? "Saving..." : "Save PDF")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(fileName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(fileName.isEmpty || isRenaming)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Rename PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func renamePDF() {
        guard !fileName.isEmpty else { return }
        
        isRenaming = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let finalURL = try PDFMerger.renamePDF(from: pdfURL, to: fileName)
                
                savePDF(destinationURL: finalURL, fileName: fileName, modificationDate: Date())
                
                DispatchQueue.main.async {
                    self.isRenaming = false
                    self.presentationMode.wrappedValue.dismiss()
                    self.onComplete(finalURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRenaming = false
                    // Handle error
                }
            }
        }
    }
}

struct FinalScreenView: View {
    let pdfURL: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State var showingPreview : Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("PDF_Merged_Successfully!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(pdfURL.lastPathComponent)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button(action: {
                        showingPreview = true
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("View_PDF")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share_PDF")
                        }
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done_")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .fullScreenCover(isPresented: $showingPreview) {
                DirectPDFView(fileURL: pdfURL) {
                   print("URL")
                }            }
            .navigationTitle("Success")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [pdfURL])
                EmptyView()
            }
        }
    }
}

//struct PDFViewer: View {
//    let pdfURL: URL
//    @Environment(\.presentationMode) var presentationMode
//    
//    var body: some View {
//        NavigationView {
//            PDFKitView(pdfURL: pdfURL)
//                .navigationTitle(pdfURL.lastPathComponent)
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button("Done") {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    }
//                }
//        }
//    }
//}


// PDF Merger Utility Class
class PDFMerger {
    static func mergePDFs(_ pdfURLs: [URL]) throws -> URL {
        let mergedDocument = PDFDocument()
        var pageIndex = 0
        
        for pdfURL in pdfURLs {
            guard let document = PDFDocument(url: pdfURL) else {
                throw PDFMergerError.invalidPDF
            }
            
            for i in 0..<document.pageCount {
                guard let page = document.page(at: i) else { continue }
                mergedDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFs/merged_pdf_\(UUID().uuidString).pdf")
        
        guard mergedDocument.write(to: tempURL) else {
            throw PDFMergerError.mergeFailed
        }
        
        return tempURL
    }
    
    static func renamePDF(from sourceURL: URL, to name: String) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                          in: .userDomainMask).first!
        let finalURL = documentsDirectory.appendingPathComponent("PDFs/\(name).pdf")
        //let finalURL = documentsDirectory.appendingPathComponent("\(name).pdf")
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: finalURL.path) {
            try FileManager.default.removeItem(at: finalURL)
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: finalURL)
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: sourceURL)
        
        savePDF(destinationURL: finalURL, fileName: name, modificationDate: Date())
        
        return finalURL
    }
}

func savePDF(destinationURL : URL , fileName: String, modificationDate: Date){
    do{
        let resourceValues = try destinationURL.resourceValues(forKeys: [
            .isUbiquitousItemKey,
            .ubiquitousItemDownloadingStatusKey,
            .fileSizeKey,
            .contentModificationDateKey
        ])
        
        let context = PersistenceController.shared.container.viewContext
        let fileItem = FileItem(context: context)
        fileItem.name = fileName
        fileItem.path = destinationURL.absoluteString // ✅ Store full URL as String
        fileItem.fileType = determineFileType(from: fileName)
        fileItem.createdDate = Date()
        fileItem.modifiedDate = modificationDate
        fileItem.fileSize = Int64(resourceValues.fileSize ?? 0)
        fileItem.isBookmarked = false
        fileItem.directoryPath = destinationURL.absoluteString
        
        PersistenceController.shared.save()
    }
    catch{
        print("Not Saved. Error: \(error)")
    }
}

enum PDFMergerError: LocalizedError {
    case invalidPDF
    case mergeFailed
    case renameFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "One or more PDF files are invalid or corrupted."
        case .mergeFailed:
            return "Failed to merge PDF files."
        case .renameFailed:
            return "Failed to rename the merged PDF file."
        }
    }
}

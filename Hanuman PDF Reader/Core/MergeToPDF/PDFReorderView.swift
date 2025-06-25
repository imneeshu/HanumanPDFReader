//
//  PDFReorderView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Foundation

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Reorder View
struct PDFReorderView: View {
    @Binding var selectedFileItems: [FileItem]
    @Environment(\.dismiss) private var dismiss
    @State private var reorderableItems: [FileItem] = []
    @State private var showPDFViewer = false
    @State private var mergedPDFURL: URL?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    let onClosePDF : () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var interstitialAdManager : InterstitialAdManager
    @State var showAd : Bool = false
    
    @State private var showRenameSheet = false
    @State private var pdfName: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "Merged_Document_\(formatter.string(from: Date()))"
    }()
    @State private var showShareSheet = false
    @State private var renamedPDFURL: URL?
    @State var bannerIsLoaded : Bool = false
    
    var body: some View {
        VStack {
            if !PremiumStatus.shared.isPremiumPurchased{
                AdBanner(adUnitID: bannerAd, bannerIsLoaded: $bannerIsLoaded)
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(Color.clear)
            }
            
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Text("Reorder_PDFs")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Reset") {
                    reorderableItems = selectedFileItems
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            // Reorderable List
            if reorderableItems.isEmpty {
                Spacer()
                Text("No_files_selected")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(reorderableItems, id: \.objectID) { file in
                        ReorderableFileRow(file: file)
                            .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveItems)
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, .constant(.active))
            }
            
            // Merge PDF Button
            if !reorderableItems.isEmpty {
                mergePDFButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .onChange(of: showAd, perform: { newValue in
            if interstitialAdManager.isLoaded && !PremiumStatus.shared.isPremiumPurchased {
                interstitialAdManager.showAd()
            }
              else{
                  mergePDFs()
              }
          })
      
          .onChange(of: interstitialAdManager.isPresenting, perform: { newValue in
              if newValue == false{
                  mergePDFs()
                  interstitialAdManager.refreshAd()
              }
          })
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showPDFViewer) {
            if let pdfURL = mergedPDFURL {
//                PDFViewerView(fileURL: pdfURL, fileName: "Merged Document")
            }
        }
        .alert("PDF Merge", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if reorderableItems.isEmpty {
                reorderableItems = selectedFileItems
            }
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Merging_PDFs...")
                            .font(.headline)
                    }
                    .padding(30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .onChange(of: renamedPDFURL, perform: { newValue in
            if renamedPDFURL != nil{
                showShareSheet = true
            }
        })
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(
                pdfName: $pdfName,
                onCancel: { showRenameSheet = false },
                onDone: {
                    Task {
                        if let mergedURL = mergedPDFURL {
                            let newURL = await renamePDF(originalURL: mergedURL, newName: pdfName)
                            renamedPDFURL = newURL
                            showRenameSheet = false
                            
                        }
                    }
                }
            )
            .presentationDetents([.fraction(0.30)])
        }
//        .sheet(isPresented: $showShareSheet) {
//            if let url = renamedPDFURL {
//                ShareSheet(items: [url])
//            }
//        }
        .fullScreenCover(isPresented: $showShareSheet) {
            SaveShareSheetContent(
                pdfURL: renamedPDFURL!,
                fileName: "",
                onViewPDF: {
                    showShareSheet = false
//                    showingPDFViewer = true
                },
                onClosePDF: {
                    onClosePDF()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Merge PDF Button
    private var mergePDFButton: some View {
        Button(action: {
            showAd = true
           // mergePDFs()
        }) {
            HStack {
                Image(systemName: "doc.on.doc")
                    .font(.title3)
                Text("Merge_PDFs")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                navy
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .disabled(isProcessing)
    }
    
    // MARK: - PDF Merge Logic
    private func mergePDFs() {
        isProcessing = true
        
        Task {
            do {
                let mergedURL = try await performPDFMerge(files: reorderableItems)
                
                await MainActor.run {
                    isProcessing = false
                    mergedPDFURL = mergedURL
                    showRenameSheet = true
                    // Reset state for new workflow
                    pdfName = "Merged_Document_\(Int(Date().timeIntervalSince1970))"
                    renamedPDFURL = nil
                    showShareSheet = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Failed to merge PDFs: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func performPDFMerge(files: [FileItem]) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let mergedDocument = PDFDocument()
                    var pageIndex = 0
                    
                    // Process each file
                    for fileItem in files {
                        guard let path = fileItem.path,
                              let fileURL = URL(string: path),
                              let document = PDFDocument(url: fileURL) else {
                            continue
                        }
                        
                        // Add all pages from this document
                        for i in 0..<document.pageCount {
                            if let page = document.page(at: i) {
                                mergedDocument.insert(page, at: pageIndex)
                                pageIndex += 1
                            }
                        }
                    }
                    
                    // Save merged document
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let mergedFileName = "PDFs/Merged_Document_\(timestamp).pdf"
                    let mergedURL = documentsPath.appendingPathComponent(
                        mergedFileName)
                   // let mergedURL = documentsPath.appendingPathComponent(mergedFileName)
                    
                    if mergedDocument.write(to: mergedURL) {
                        continuation.resume(returning: mergedURL)
                    } else {
                        continuation.resume(throwing: PDFMergeError.writeFailed)
                    }
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Move Items
    private func moveItems(from source: IndexSet, to destination: Int) {
        reorderableItems.move(fromOffsets: source, toOffset: destination)
    }
}


// MARK: - PDF Rename Helper
 func renamePDF(originalURL: URL, newName: String) async -> URL {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let sanitized = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    let finalName = sanitized.isEmpty ? originalURL.lastPathComponent : sanitized + ".pdf"
    let destinationURL = documentsPath.appendingPathComponent(finalName)
    do {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: originalURL, to: destinationURL)
        savePDF(
            destinationURL: destinationURL,
            fileName: newName,
            modificationDate: Date()
        )
        return destinationURL
    } catch {
        print("Rename failed: \(error)")
        return originalURL
    }
}

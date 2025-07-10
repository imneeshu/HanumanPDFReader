//
//  FileListViewForSelection.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - File List View
struct FileListViewForSelection: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedFiles: [URL] = []
    @State private var selectedFileItems: [FileItem] = []
    @State private var showReorderView = false
    @State private var showFileImporter = false
    @State var fileSelected : Bool = false
    @Binding var listFlow : ListFlow
    @State var showSplitView : Bool = false
    @State private var selectedPages: Set<Int> = []
    @State private var pdfDocument: PDFDocument?
    @State private var refreshID = UUID() // Add this to trigger view refresh
    let onClosePDF: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State var bannerIsLoaded : Bool = false
    
    var body: some View {
        ZStack {
            // MARK: PDF Reorder View after Continue Button
            NavigationLink(
                destination: PDFReorderView(selectedFileItems: $selectedFileItems,
                                            onClosePDF: {
                                                // Clear selections and refresh view
                                                selectedFileItems = []
                                                selectedFiles = []
                                                refreshID = UUID() // Trigger view refresh
                                                
                                                // Refresh the view model data if needed
                                                viewModel.refreshFileItems() // Add this method to your MainViewModel
                                                
                                                presentationMode.wrappedValue.dismiss()
                                            })
                    .navigationBarTitleDisplayMode(.inline),
                isActive: $showReorderView,
                label: { EmptyView() }
            )
            
            // MARK: PDF Split View after PDF Selection
            NavigationLink(
                destination: SplitPDFView(
                    pdfDocument: $pdfDocument,
                    selectedPages: $selectedPages,
                    onClosePDF: {
                        onClosePDF()
                        selectedPages = []
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                    .navigationBarTitleDisplayMode(.inline),
                isActive: $showSplitView,
                label: { EmptyView() }
            )
            
            
            VStack {
                if !PremiumStatus.shared.isPremiumPurchased{
                    AdBanner(adUnitID: bannerAd, bannerIsLoaded: $bannerIsLoaded)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .background(Color.clear)
                }
                
                if viewModel.fileItems.filter({ $0.fileTypeEnum == .pdf }).isEmpty {
                    EmptyStateView(
                        title: "No Files Found",
                        subtitle: "Add some documents to get started"
                    )
                } else {
                    List {
                        ForEach(viewModel.fileItems.filter { $0.fileTypeEnum == .pdf }, id: \.objectID) { file in
                            FileRowViewForSelection(
                                file: file,
                                isSelected: selectedFiles.contains(createFileURL(file: file) ?? URL(fileURLWithPath: "")),
                                onSelectionToggle: {
                                    if listFlow == .merge{
                                        toggleSelection(for: file)
                                        viewModel.markAsRecentlyAccessed(file)
                                    }
                                    else if listFlow == .split  {
                                        selectionForSplit(for: file)
                                    }
                                },
                                listFlow: $listFlow
                            )
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, bannerIsLoaded ? 20 : 0)
                    .listStyle(PlainListStyle())
                    .id(refreshID) // Add this to make the list refreshable
                }
                
                // Continue Button
                if selectedFiles.count > 1 {
                    Button(action: {
                        // Prepare selected PDF file items and navigate to reorder view
                        selectedFileItems = viewModel.fileItems.filter { file in
                            guard let fileURL = createFileURL(file: file) else { return false }
                            return file.fileTypeEnum == .pdf && selectedFiles.contains(fileURL)
                        }
                        showReorderView = true
                    }) {
                        Text("Continue_")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                navy
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
            
            // Floating Import Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingImportButton
                        .padding(.trailing, 20)
                        .padding(.bottom, selectedFiles.count > 1 ? 105 : 20)
                }
            }
        }
        .onChange(of: selectedFiles, perform: { newValue in
            if listFlow == .split{
                showSplitView = true
            }
        })
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .text, UTType(filenameExtension: "doc")!, UTType(filenameExtension: "docx")!],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.saveInCoreData(fileURLs: urls)
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
    }
    
    // MARK: - Floating Import Button
    private var floatingImportButton: some View {
        Button(action: {
            showFileImporter = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    navy
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    private func createFileURL(file: FileItem) -> URL? {
        guard let path = file.path,
              let fileURL = URL(string: path),
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return fileURL
    }
    
    // MARK: - Selection Logic
    private func toggleSelection(for file: FileItem) {
        guard file.fileTypeEnum == .pdf else { return }
        guard let fileURL = createFileURL(file: file) else { return }
        
        if let index = selectedFiles.firstIndex(of: fileURL) {
            selectedFiles.remove(at: index)
        } else {
            selectedFiles.append(fileURL)
        }
    }
    
    func allFileToogleSelection(){
        for file in selectedFileItems{
            toggleSelection(for: file)
        }
    }
    
    // MARK: - Selection
     func selectionForSplit(for file: FileItem) {
        guard file.fileTypeEnum == .pdf else { return }
        guard let fileURL = createFileURL(file: file) else { return }
        pdfDocument = PDFDocument(url: fileURL)
        selectedPages.removeAll()
        selectedFiles.append(fileURL)
    }
}

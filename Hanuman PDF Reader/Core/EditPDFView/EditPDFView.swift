//
//  EditPDFView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Main Edit PDF View
struct EditPDFView: View {
    @State private var showingDocumentPicker = false
    @State private var selectedPDFURL: URL?
    @State private var showingPDFEditor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if selectedPDFURL == nil {
                    // Welcome Screen
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("PDF_Editor")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Select_a_PDF_to_start _diting")
//                            .font(.subtitle)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Select_PDF")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                } else {
                    // PDF Selected - Show Info
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("PDF_Selected")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(selectedPDFURL?.lastPathComponent ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button("Edit_PDF") {
                                showingPDFEditor = true
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Select_Different_PDF") {
                                showingDocumentPicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("PDF_Editor")
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerEdit(selectedURL: $selectedPDFURL)
        }
        .fullScreenCover(isPresented: $showingPDFEditor) {
            if let url = selectedPDFURL {
                PDFEditorView(pdfURL: url, isPresented: $showingPDFEditor)
            }
        }
    }
}

// MARK: - Document Picker
struct DocumentPickerEdit: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerEdit
        
        init(_ parent: DocumentPickerEdit) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.selectedURL = url
            }
            parent.dismiss()
        }
    }
}

// MARK: - PDF Editor View
struct PDFEditorView: View {
    let pdfURL: URL
    @Binding var isPresented: Bool
    @State private var pdfDocument: PDFDocument?
    @State private var showingFilters = false
    @State private var selectedFilter: PDFFilter = .none
    @State private var searchText = ""
    @State private var showingColorPicker = false
    @State private var selectedAnnotationType: AnnotationType = .highlight
    @State private var selectedColor: Color = .yellow
    @State private var showingDigitalSignature = false
    @State private var annotations: [PDFAnnotation] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Top Toolbar
                HStack {
                    Button("Filters") {
                        showingFilters = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search in PDF", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .frame(maxWidth: 200)
                    
                    Spacer()
                    
                    Button("Sign") {
                        showingDigitalSignature = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                // Annotation Toolbar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(AnnotationType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedAnnotationType = type
                                if type.needsColor {
                                    showingColorPicker = true
                                }
                            }) {
                                VStack {
                                    Image(systemName: type.icon)
                                        .font(.title2)
                                    Text(type.title)
                                        .font(.caption)
                                }
                                .foregroundColor(selectedAnnotationType == type ? .blue : .primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    selectedAnnotationType == type ? 
                                    Color.blue.opacity(0.2) : Color.clear
                                )
                                .cornerRadius(8)
                            }
                        }
                        
                        // Color Selector
                        ColorSelectorView(selectedColor: $selectedColor)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // PDF Viewer
                if let document = pdfDocument {
                    PDFViewRepresentable(
                        document: document,
                        filter: selectedFilter,
                        searchText: searchText,
                        annotationType: selectedAnnotationType,
                        annotationColor: selectedColor
                    )
                } else {
                    ProgressView("Loading PDF...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("PDF Editor")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Close") {
//                        isPresented = false
//                    }
//                }
//            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSelectionViewEdit(selectedFilter: $selectedFilter)
        }
        .sheet(isPresented: $showingDigitalSignature) {
            DigitalSignatureView()
        }
        .onAppear {
            loadPDF()
        }
    }
    
    private func loadPDF() {
        if pdfURL.startAccessingSecurityScopedResource() {
            pdfDocument = PDFDocument(url: pdfURL)
            pdfURL.stopAccessingSecurityScopedResource()
        }
    }
}

// MARK: - Filter Selection View
struct FilterSelectionViewEdit: View {
    @Binding var selectedFilter: PDFFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(PDFFilter.allCases, id: \.self) { filter in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(filter.title)
                                .font(.headline)
                            Text(filter.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFilter == filter {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFilter = filter
                        dismiss()
                    }
                }
            }
            .navigationTitle("PDF Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .background(navy)
                }
            }
        }
    }
}

// MARK: - Color Selector View
struct ColorSelectorView: View {
    @Binding var selectedColor: Color
    
    let colors: [Color] = [
        .yellow, .orange, .red, .pink, .purple, .blue, .cyan, .green, .mint, .brown, .gray, .black
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Color:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        selectedColor = color
                    }
            }
        }
    }
}

// MARK: - Digital Signature View
struct DigitalSignatureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var signaturePath = Path()
    @State private var currentPath = Path()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Draw_Your_Signature")
                    .font(.headline)
                    .padding()
                
                // Signature Canvas
                Canvas { context, size in
                    context.stroke(signaturePath, with: .color(.blue), lineWidth: 3)
                    context.stroke(currentPath, with: .color(.blue), lineWidth: 3)
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .border(Color.gray, width: 1)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if currentPath.isEmpty {
                                currentPath.move(to: value.location)
                            } else {
                                currentPath.addLine(to: value.location)
                            }
                        }
                        .onEnded { _ in
                            signaturePath.addPath(currentPath)
                            currentPath = Path()
                        }
                )
                .padding()
                
                HStack {
                    Button("Clear") {
                        signaturePath = Path()
                        currentPath = Path()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Add Signature") {
                        // Add signature to PDF
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(signaturePath.isEmpty)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Digital Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - PDF View Representable
struct PDFViewRepresentable: UIViewRepresentable {
    let document: PDFDocument
    let filter: PDFFilter
    let searchText: String
    let annotationType: AnnotationType
    let annotationColor: Color
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Enable selection for text highlighting
//        pdfView.isEnabled = true
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Apply filter
        applyFilter(to: pdfView)
        
        // Handle search
        if !searchText.isEmpty {
//            performSearch(in: pdfView)
        }
    }
    
    private func applyFilter(to pdfView: PDFView) {
        // Apply filter logic based on selected filter
        switch filter {
        case .none:
            // No filter
            break
        case .grayscale:
            // Apply grayscale filter
            applyGrayscaleFilter(to: pdfView)
        case .sepia:
            // Apply sepia filter
            applySepiaFilter(to: pdfView)
        case .highContrast:
            // Apply high contrast filter
            applyHighContrastFilter(to: pdfView)
        }
    }
    
//    private func performSearch(in pdfView: PDFView) {
//        guard let document = pdfView.document else { return }
//        
//        // Clear previous search results
//        pdfView.highlightedSelections = nil
//        
//        // Perform search
//        var selections: [PDFSelection] = []
//        for pageIndex in 0..<document.pageCount {
//            if let page = document.page(at: pageIndex) {
//                let pageSelections = page.selections(for: searchText, options: [.caseInsensitive])
//                selections.append(contentsOf: pageSelections)
//            }
//        }
//        
//        // Highlight search results
//        pdfView.highlightedSelections = selections
//        
//        // Navigate to first result
//        if let firstSelection = selections.first {
//            pdfView.go(to: firstSelection)
//        }
//    }
    
    private func applyGrayscaleFilter(to pdfView: PDFView) {
        // Implementation for grayscale filter
        // This would typically involve Core Image filters
    }
    
    private func applySepiaFilter(to pdfView: PDFView) {
        // Implementation for sepia filter
    }
    
    private func applyHighContrastFilter(to pdfView: PDFView) {
        // Implementation for high contrast filter
    }
}

// MARK: - Supporting Enums and Models
enum PDFFilter: CaseIterable {
    case none
    case grayscale
    case sepia
    case highContrast
    
    var title: String {
        switch self {
        case .none: return "No Filter"
        case .grayscale: return "Grayscale"
        case .sepia: return "Sepia"
        case .highContrast: return "High Contrast"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "Original document colors"
        case .grayscale: return "Convert to black and white"
        case .sepia: return "Vintage sepia tone"
        case .highContrast: return "Enhanced contrast for readability"
        }
    }
}

enum AnnotationType: CaseIterable {
    case highlight
    case underline
    case strikethrough
    case freehand
    case text
    case arrow
    
    var title: String {
        switch self {
        case .highlight: return "Highlight"
        case .underline: return "Underline"
        case .strikethrough: return "Strike"
        case .freehand: return "Draw"
        case .text: return "Text"
        case .arrow: return "Arrow"
        }
    }
    
    var icon: String {
        switch self {
        case .highlight: return "highlighter"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .freehand: return "pencil.tip"
        case .text: return "text.cursor"
        case .arrow: return "arrow.up.right"
        }
    }
    
    var needsColor: Bool {
        switch self {
        case .highlight, .underline, .strikethrough, .freehand:
            return true
        case .text, .arrow:
            return false
        }
    }
}

// MARK: - Preview
struct EditPDFView_Previews: PreviewProvider {
    static var previews: some View {
        EditPDFView()
    }
}

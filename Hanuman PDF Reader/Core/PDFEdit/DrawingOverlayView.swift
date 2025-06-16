////
////  DrawingOverlayView.swift
////  Hanuman PDF Reader
////
////  Created by Neeshu Kumar on 16/06/25.
////
//
//import UIKit
//import PDFKit
//import SwiftUI
//
//// MARK: - Drawing Overlay View
//
//class DrawingOverlayView: UIView {
//    private var currentPath: UIBezierPath?
//    private var paths: [UIBezierPath] = []
//    private var strokeColor: UIColor = UIColor.red
//    private var strokeWidth: CGFloat = 2.0
//    
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//        
//        strokeColor.setStroke()
//        
//        for path in paths {
//            path.lineWidth = strokeWidth
//            path.stroke()
//        }
//        
//        if let currentPath = currentPath {
//            currentPath.lineWidth = strokeWidth
//            currentPath.stroke()
//        }
//    }
//    
//    func startDrawing(at point: CGPoint) {
//        currentPath = UIBezierPath()
//        currentPath?.move(to: point)
//    }
//    
//    func continueDrawing(to point: CGPoint) {
//        currentPath?.addLine(to: point)
//        setNeedsDisplay()
//    }
//    
//    func endDrawing() {
//        if let path = currentPath {
//            paths.append(path)
//            currentPath = nil
//        }
//    }
//    
//    func clearDrawing() {
//        paths.removeAll()
//        currentPath = nil
//        setNeedsDisplay()
//    }
//    
//    func getLastPath() -> UIBezierPath? {
//        return paths.last
//    }
//    
//    func removeLastPath() {
//        if !paths.isEmpty {
//            paths.removeLast()
//            setNeedsDisplay()
//        }
//    }
//}
//
//// MARK: - Enhanced PDF View Controller
//
//class EnhancedPDFViewController: UIViewController {
//    private let fileURL: URL
//    private var pdfView: PDFView!
//    private var pdfDocument: PDFDocument?
//    private var searchBar: UISearchBar!
//    private var toolbar: UIToolbar!
//    private var pageLabel: UILabel!
//    private var pageTextField: UITextField!
//    private var currentEditMode: EditMode = .none
//    private var isVerticalMode = true
//    private var searchResults: [PDFSelection] = []
//    private var currentSearchIndex = 0
//    private var drawingOverlay: DrawingOverlayView!
//    private var annotationHistory: [PDFAnnotation] = []
//    
//    var onDismiss: (() -> Void)?
//    
//    enum EditMode {
//        case none
//        case highlight
//        case underline
//        case strikethrough
//        case drawing
//        case textSelection
//    }
//    
//    init(fileURL: URL) {
//        self.fileURL = fileURL
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        loadPDF()
//        setupNotifications()
//        setupGestures()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        
//        // Navigation bar setup
//        navigationItem.title = fileURL.lastPathComponent
//        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareDocument))
//        
//        // Search bar
//        searchBar = UISearchBar()
//        searchBar.delegate = self
//        searchBar.placeholder = "Search in PDF"
//        searchBar.searchBarStyle = .minimal
//        view.addSubview(searchBar)
//        
//        // PDF View
//        pdfView = PDFView()
//        pdfView.autoScales = true
//        pdfView.displayMode = .singlePageContinuous
//        pdfView.displayDirection = .vertical
//        pdfView.delegate = self
//        view.addSubview(pdfView)
//        
//        // Drawing overlay for free drawing
//        drawingOverlay = DrawingOverlayView()
//        drawingOverlay.backgroundColor = .clear
//        drawingOverlay.isUserInteractionEnabled = false
//        view.addSubview(drawingOverlay)
//        
//        // Toolbar
//        setupToolbar()
//        
//        // Page navigation
//        setupPageNavigation()
//        
//        // Constraints
//        setupConstraints()
//    }
//    
//    private func setupToolbar() {
//        toolbar = UIToolbar()
//        
//        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditMenu))
//        let viewModeButton = UIBarButtonItem(title: "View", style: .plain, target: self, action: #selector(toggleViewMode))
//        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let zoomInButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(zoomIn))
//        let zoomOutButton = UIBarButtonItem(title: "−", style: .plain, target: self, action: #selector(zoomOut))
//        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoLastAnnotation))
//        
//        toolbar.items = [editButton, flexSpace, viewModeButton, flexSpace, undoButton, zoomOutButton, zoomInButton]
//        view.addSubview(toolbar)
//    }
//    
//    private func setupPageNavigation() {
//        let pageContainer = UIView()
//        pageContainer.backgroundColor = .systemGray6
//        pageContainer.layer.cornerRadius = 8
//        
//        let prevButton = UIButton(type: .system)
//        prevButton.setTitle("◀", for: .normal)
//        prevButton.addTarget(self, action: #selector(previousPage), for: .touchUpInside)
//        
//        let nextButton = UIButton(type: .system)
//        nextButton.setTitle("▶", for: .normal)
//        nextButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
//        
//        pageTextField = UITextField()
//        pageTextField.borderStyle = .roundedRect
//        pageTextField.textAlignment = .center
//        pageTextField.keyboardType = .numberPad
//        pageTextField.delegate = self
//        pageTextField.addTarget(self, action: #selector(pageTextFieldChanged), for: .editingDidEnd)
//        
//        pageLabel = UILabel()
//        pageLabel.text = "of 0"
//        pageLabel.textAlignment = .center
//        
//        [prevButton, pageTextField, pageLabel, nextButton].forEach { pageContainer.addSubview($0) }
//        view.addSubview(pageContainer)
//        
//        // Page container constraints
//        pageContainer.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            pageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            pageContainer.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -10),
//            pageContainer.heightAnchor.constraint(equalToConstant: 40),
//            pageContainer.widthAnchor.constraint(equalToConstant: 200)
//        ])
//        
//        // Page navigation buttons constraints
//        [prevButton, pageTextField, pageLabel, nextButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
//        
//        NSLayoutConstraint.activate([
//            prevButton.leadingAnchor.constraint(equalTo: pageContainer.leadingAnchor, constant: 8),
//            prevButton.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
//            prevButton.widthAnchor.constraint(equalToConstant: 30),
//            
//            pageTextField.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 8),
//            pageTextField.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
//            pageTextField.widthAnchor.constraint(equalToConstant: 50),
//            
//            pageLabel.leadingAnchor.constraint(equalTo: pageTextField.trailingAnchor, constant: 4),
//            pageLabel.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
//            pageLabel.widthAnchor.constraint(equalToConstant: 50),
//            
//            nextButton.leadingAnchor.constraint(equalTo: pageLabel.trailingAnchor, constant: 8),
//            nextButton.trailingAnchor.constraint(equalTo: pageContainer.trailingAnchor, constant: -8),
//            nextButton.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
//            nextButton.widthAnchor.constraint(equalToConstant: 30)
//        ])
//    }
//    
//    private func setupConstraints() {
//        [searchBar, pdfView, drawingOverlay, toolbar].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
//        
//        NSLayoutConstraint.activate([
//            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            
//            pdfView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
//            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            pdfView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
//            
//            drawingOverlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
//            drawingOverlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
//            drawingOverlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
//            drawingOverlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor),
//            
//            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        ])
//    }
//    
//    private func setupGestures() {
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
//        pdfView.addGestureRecognizer(tapGesture)
//        
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        drawingOverlay.addGestureRecognizer(panGesture)
//    }
//    
//    private func loadPDF() {
//        guard let document = PDFDocument(url: fileURL) else {
//            showAlert(title: "Error", message: "Could not load PDF document")
//            return
//        }
//        
//        pdfDocument = document
//        pdfView.document = document
//        updatePageInfo()
//    }
//    
//    private func setupNotifications() {
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(pdfViewPageChanged),
//            name: .PDFViewPageChanged,
//            object: pdfView
//        )
//    }
//    
//    // MARK: - Gesture Handlers
//    
//    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
//        guard currentEditMode != .none else { return }
//        
//        let point = gesture.location(in: pdfView)
//        guard let page = pdfView.page(for: point, nearest: true) else { return }
//        
//        let convertedPoint = pdfView.convert(point, to: page)
//        
//        switch currentEditMode {
//        case .textSelection:
//            selectTextAt(point: convertedPoint, in: page)
//        default:
//            break
//        }
//    }
//    
//    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
//        guard currentEditMode == .drawing else { return }
//        
//        let point = gesture.location(in: drawingOverlay)
//        
//        switch gesture.state {
//        case .began:
//            drawingOverlay.startDrawing(at: point)
//        case .changed:
//            drawingOverlay.continueDrawing(to: point)
//        case .ended:
//            drawingOverlay.endDrawing()
//            // Convert drawing to PDF annotation
//            addDrawingAnnotationToPDF()
//        default:
//            break
//        }
//    }
//    
//    // MARK: - Actions
//    
//    @objc private func dismissView() {
//        dismiss(animated: true) { [weak self] in
//            self?.onDismiss?()
//        }
//    }
//    
//    @objc private func shareDocument() {
//        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
//        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
//        present(activityVC, animated: true)
//    }
//    
//    @objc private func toggleEditMenu() {
//        let alert = UIAlertController(title: "Edit Mode", message: "Select editing tool", preferredStyle: .actionSheet)
//        
//        alert.addAction(UIAlertAction(title: "Select Text", style: .default) { _ in
//            self.currentEditMode = .textSelection
//            self.showEditModeIndicator("Text Selection Mode")
//            self.drawingOverlay.isUserInteractionEnabled = false
//        })
//        
//        alert.addAction(UIAlertAction(title: "Highlight", style: .default) { _ in
//            self.currentEditMode = .highlight
//            self.showEditModeIndicator("Highlight Mode")
//            self.drawingOverlay.isUserInteractionEnabled = false
//        })
//        
//        alert.addAction(UIAlertAction(title: "Underline", style: .default) { _ in
//            self.currentEditMode = .underline
//            self.showEditModeIndicator("Underline Mode")
//            self.drawingOverlay.isUserInteractionEnabled = false
//        })
//        
//        alert.addAction(UIAlertAction(title: "Strikethrough", style: .default) { _ in
//            self.currentEditMode = .strikethrough
//            self.showEditModeIndicator("Strikethrough Mode")
//            self.drawingOverlay.isUserInteractionEnabled = false
//        })
//        
//        alert.addAction(UIAlertAction(title: "Draw", style: .default) { _ in
//            self.currentEditMode = .drawing
//            self.showEditModeIndicator("Drawing Mode")
//            self.drawingOverlay.isUserInteractionEnabled = true
//        })
//        
//        alert.addAction(UIAlertAction(title: "Exit Edit Mode", style: .destructive) { _ in
//            self.currentEditMode = .none
//            self.showEditModeIndicator("View Mode")
//            self.drawingOverlay.isUserInteractionEnabled = false
//        })
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        
//        if let popover = alert.popoverPresentationController {
//            popover.permittedArrowDirections = .up
//            popover.sourceView = view
//            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 50, width: 0, height: 0)
//        }
//        
//        present(alert, animated: true)
//    }
//    
//    @objc private func toggleViewMode() {
//        isVerticalMode.toggle()
//        
//        if isVerticalMode {
//            pdfView.displayDirection = .vertical
//            pdfView.displayMode = .singlePageContinuous
//        } else {
//            pdfView.displayDirection = .horizontal
//            pdfView.displayMode = .singlePage
//        }
//        
//        showEditModeIndicator(isVerticalMode ? "Vertical View" : "Horizontal View")
//    }
//    
//    @objc private func zoomIn() {
//        pdfView.scaleFactor *= 1.2
//    }
//    
//    @objc private func zoomOut() {
//        pdfView.scaleFactor /= 1.2
//    }
//    
//    @objc private func undoLastAnnotation() {
//        if !annotationHistory.isEmpty {
//            let lastAnnotation = annotationHistory.removeLast()
//            lastAnnotation.page?.removeAnnotation(lastAnnotation)
//        } else {
//            drawingOverlay.removeLastPath()
//        }
//    }
//    
//    @objc private func previousPage() {
//        pdfView.goToPreviousPage(nil)
//        updatePageInfo()
//    }
//    
//    @objc private func nextPage() {
//        pdfView.goToNextPage(nil)
//        updatePageInfo()
//    }
//    
//    @objc private func pageTextFieldChanged() {
//        guard let text = pageTextField.text,
//              let pageNumber = Int(text),
//              let document = pdfDocument,
//              pageNumber > 0,
//              pageNumber <= document.pageCount else {
//            updatePageInfo()
//            return
//        }
//        
//        if let page = document.page(at: pageNumber - 1) {
//            pdfView.go(to: page)
//            updatePageInfo()
//        }
//    }
//    
//    @objc private func pdfViewPageChanged() {
//        updatePageInfo()
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func updatePageInfo() {
//        guard let document = pdfDocument,
//              let currentPage = pdfView.currentPage else {
//            pageTextField.text = "1"
//            pageLabel.text = "of 0"
//            return
//        }
//        
//        let currentPageIndex = document.index(for: currentPage) + 1
//        pageTextField.text = "\(currentPageIndex)"
//        pageLabel.text = "of \(document.pageCount)"
//    }
//    
//    private func showEditModeIndicator(_ message: String) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        present(alert, animated: true)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            alert.dismiss(animated: true)
//        }
//    }
//    
//    private func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
//    private func performSearch(_ searchText: String) {
//        guard let document = pdfDocument else { return }
//        
//        searchResults.removeAll()
//        currentSearchIndex = 0
//        
//        // Use document-level search instead of page-level
//        let selections = document.findString(searchText, withOptions: .caseInsensitive)
//        searchResults.append(contentsOf: selections)
//        
//        if !searchResults.isEmpty {
//            highlightSearchResult(at: 0)
//        }
//    }
//    
//    private func highlightSearchResult(at index: Int) {
//        guard index < searchResults.count else { return }
//        
//        let selection = searchResults[index]
//        pdfView.setCurrentSelection(selection, animate: true)
//        pdfView.go(to: selection)
//    }
//    
//    private func selectTextAt(point: CGPoint, in page: PDFPage) {
//        // Create a selection around the tapped point
//        let selection = page.selection(for: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
//        
//        if let selection = selection {
//            pdfView.setCurrentSelection(selection, animate: true)
//            
//            // Show annotation options
//            showAnnotationOptions(for: selection)
//        }
//    }
//    
//    private func showAnnotationOptions(for selection: PDFSelection) {
//        let alert = UIAlertController(title: "Annotate", message: "Choose annotation type", preferredStyle: .actionSheet)
//        
//        alert.addAction(UIAlertAction(title: "Highlight", style: .default) { _ in
//            self.addHighlightAnnotation(for: selection, color: .yellow)
//        })
//        
//        alert.addAction(UIAlertAction(title: "Underline", style: .default) { _ in
//            self.addUnderlineAnnotation(for: selection)
//        })
//        
//        alert.addAction(UIAlertAction(title: "Strikethrough", style: .default) { _ in
//            self.addStrikethroughAnnotation(for: selection)
//        })
//        
//        alert.addAction(UIAlertAction(title: "Note", style: .default) { _ in
//            self.addNoteAnnotation(for: selection)
//        })
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        
//        if let popover = alert.popoverPresentationController {
//            popover.sourceView = pdfView
//            popover.sourceRect = CGRect(x: pdfView.bounds.midX, y: pdfView.bounds.midY, width: 0, height: 0)
//        }
//        
//        present(alert, animated: true)
//    }
//    
//    private func addHighlightAnnotation(for selection: PDFSelection, color: UIColor) {
//        guard let page = selection.pages.first else { return }
//        
//        let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
//        highlight.color = color
//        highlight.contents = "Highlighted text"
//        
//        page.addAnnotation(highlight)
//        annotationHistory.append(highlight)
//    }
//    
//    private func addUnderlineAnnotation(for selection: PDFSelection) {
//        guard let page = selection.pages.first else { return }
//        
//        let underline = PDFAnnotation(bounds: selection.bounds(for: page), forType: .underline, withProperties: nil)
//        underline.color = UIColor.blue
//        underline.contents = "Underlined text"
//        
//        page.addAnnotation(underline)
//        annotationHistory.append(underline)
//    }
//    
//    private func addStrikethroughAnnotation(for selection: PDFSelection) {
//        guard let page = selection.pages.first else { return }
//        
//        let strikethrough = PDFAnnotation(bounds: selection.bounds(for: page), forType: .strikeOut, withProperties: nil)
//        strikethrough.color = UIColor.red
//        strikethrough.contents = "Strikethrough text"
//        
//        page.addAnnotation(strikethrough)
//        annotationHistory.append(strikethrough)
//    }
//    
//    private func addNoteAnnotation(for selection: PDFSelection) {
//        let alert = UIAlertController(title: "Add Note", message: "Enter your note", preferredStyle: .alert)
//        
//        alert.addTextField { textField in
//            textField.placeholder = "Enter note text"
//        }
//        
//        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
//            guard let noteText = alert.textFields?.first?.text,
//                  !noteText.isEmpty,
//                  let page = selection.pages.first else { return }
//            
//            let bounds = selection.bounds(for: page)
//            let note = PDFAnnotation(bounds: bounds, forType: .text, withProperties: nil)
//            note.contents = noteText
//            note.iconType = .note
//            note.color = UIColor.orange
//            
//            page.addAnnotation(note)
//            self.annotationHistory.append(note)
//        })
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        present(alert, animated: true)
//    }
//    
//    private func addDrawingAnnotationToPDF() {
//        guard let currentPage = pdfView.currentPage,
//              let path = drawingOverlay.getLastPath() else { return }
//        
//        // Convert the drawing path to PDF coordinate system
//        let pdfBounds = pdfView.convert(path.bounds, to: currentPage)
//        
//        // Create ink annotation with proper path data
//        let pathArray = convertBezierPathToInkPaths(path, in: currentPage)
//        
//        let inkAnnotation = PDFAnnotation(bounds: pdfBounds, forType: .ink, withProperties: [
//            "InkList": pathArray
//        ])
//        inkAnnotation.color = UIColor.red
//        
//        currentPage.addAnnotation(inkAnnotation)
//        annotationHistory.append(inkAnnotation)
//        
//        // Clear the drawing overlay
//        drawingOverlay.clearDrawing()
//    }
//    
//    private func convertBezierPathToInkPaths(_ bezierPath: UIBezierPath, in page: PDFPage) -> [[NSValue]] {
//        var pathArray: [[NSValue]] = []
//        var currentPathSegment: [NSValue] = []
//        
//        // Struct to pass necessary context
//        struct Context {
//            var pdfView: PDFView
//            var page: PDFPage
//            var currentPathSegment: UnsafeMutablePointer<[NSValue]>
//            var pathArray: UnsafeMutablePointer<[[NSValue]]>
//        }
//        
//        // Create context
//        var currentSegment = currentPathSegment
//        var allPaths = pathArray
//        var context = Context(pdfView: self.pdfView, page: page, currentPathSegment: &currentSegment, pathArray: &allPaths)
//        
//        let contextPointer = UnsafeMutableRawPointer(&context)
//        
//        bezierPath.cgPath.apply(info: contextPointer) { (info, elementPointer) in
//            guard let info = info else { return }
//            
//            let context = info.assumingMemoryBound(to: Context.self).pointee
//            let type = elementPointer.pointee.type
//            let points = elementPointer.pointee.points
//            
//            switch type {
//            case .moveToPoint:
//                if !context.currentPathSegment.pointee.isEmpty {
//                    context.pathArray.pointee.append(context.currentPathSegment.pointee)
//                    context.currentPathSegment.pointee.removeAll()
//                }
//                let convertedPoint = context.pdfView.convert(points[0], to: context.page)
//                context.currentPathSegment.pointee.append(NSValue(cgPoint: convertedPoint))
//                
//            case .addLineToPoint:
//                let convertedPoint = context.pdfView.convert(points[0], to: context.page)
//                context.currentPathSegment.pointee.append(NSValue(cgPoint: convertedPoint))
//                
//            case .addQuadCurveToPoint, .addCurveToPoint:
//                let count = type == .addQuadCurveToPoint ? 2 : 3
//                let convertedPoint = context.pdfView.convert(points[count - 1], to: context.page)
//                context.currentPathSegment.pointee.append(NSValue(cgPoint: convertedPoint))
//                
//            case .closeSubpath:
//                break
//                
//            @unknown default:
//                break
//            }
//        }
//
//        // Append the final segment
//        if !currentSegment.isEmpty {
//            allPaths.append(currentSegment)
//        }
//        
//        return allPaths
//    }
//
//    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//}
//
//// MARK: - PDFView Delegate
//
//extension EnhancedPDFViewController: PDFViewDelegate {
//    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
//        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//    }
//}
//
//// MARK: - UISearchBar Delegate
//
//extension EnhancedPDFViewController: UISearchBarDelegate {
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchText.isEmpty {
//            searchResults.removeAll()
//            pdfView.setCurrentSelection(nil, animate: false)
//        }
//    }
//    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
//        performSearch(searchText)
//        searchBar.resignFirstResponder()
//    }
//    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text = ""
//        searchBar.resignFirstResponder()
//        searchResults.removeAll()
//        pdfView.setCurrentSelection(nil, animate: false)
//    }
//}
//
//// MARK: - UITextField Delegate
//
//extension EnhancedPDFViewController: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        pageTextFieldChanged()
//        return true
//    }
//    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        let allowedCharacters = CharacterSet.decimalDigits
//        let characterSet = CharacterSet(charactersIn: string)
//        return allowedCharacters.isSuperset(of: characterSet)
//    }
//}
//
//
//// MARK: - Simplified Direct PDF View
//struct DirectPDFView: UIViewControllerRepresentable {
//    let fileURL: URL
//    let onDismiss: () -> Void
//    
//    func makeUIViewController(context: Context) -> UINavigationController {
//        let pdfViewController = EnhancedPDFViewController(fileURL: fileURL)
//        pdfViewController.onDismiss = onDismiss
//        return UINavigationController(rootViewController: pdfViewController)
//    }
//    
//    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
//        // No updates needed
//    }
//}


//
//  EnhancedPDFViewController.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import UIKit
import PDFKit
import SwiftUI

// MARK: - Drawing Overlay View

class DrawingOverlayView: UIView {
    private var currentPath: UIBezierPath?
    private var paths: [UIBezierPath] = []
    private var strokeColor: UIColor = UIColor.red
    private var strokeWidth: CGFloat = 2.0
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        strokeColor.setStroke()
        
        for path in paths {
            path.lineWidth = strokeWidth
            path.stroke()
        }
        
        if let currentPath = currentPath {
            currentPath.lineWidth = strokeWidth
            currentPath.stroke()
        }
    }
    
    func startDrawing(at point: CGPoint) {
        currentPath = UIBezierPath()
        currentPath?.move(to: point)
    }
    
    func continueDrawing(to point: CGPoint) {
        currentPath?.addLine(to: point)
        setNeedsDisplay()
    }
    
    func endDrawing() {
        if let path = currentPath {
            paths.append(path)
            currentPath = nil
        }
    }
    
    func clearDrawing() {
        paths.removeAll()
        currentPath = nil
        setNeedsDisplay()
    }
    
    func getLastPath() -> UIBezierPath? {
        return paths.last
    }
    
    func removeLastPath() {
        if !paths.isEmpty {
            paths.removeLast()
            setNeedsDisplay()
        }
    }
}

// MARK: - Enhanced PDF View Controller

class EnhancedPDFViewController: UIViewController {
    private let fileURL: URL
    private var pdfView: PDFView!
    private var pdfDocument: PDFDocument?
    private var searchBar: UISearchBar!
    private var mainToolbar: UIToolbar!
    private var editToolbar: UIToolbar!
    private var annotationToolbar: UIToolbar!
    private var textToolbar: UIToolbar!
    private var pageLabel: UILabel!
    private var pageTextField: UITextField!
    private var pageContainer: UIView!
    
    // Edit modes
    private var currentEditMode: EditMode = .none
    private var currentSubMode: SubMode = .none
    private var isEditModeActive = false
    private var isVerticalMode = true
    
    // Search & annotations
    private var searchResults: [PDFSelection] = []
    private var currentSearchIndex = 0
    private var drawingOverlay: DrawingOverlayView!
    private var annotationHistory: [PDFAnnotation] = []
    
    // Text properties
    private var currentTextSize: CGFloat = 12.0
    private var currentTextColor: UIColor = .black
    
    var onDismiss: (() -> Void)?
    
    enum EditMode {
        case none
        case annotate
        case addText
    }
    
    enum SubMode {
        case none
        case highlight
        case underline
        case strikethrough
        case drawing
        case copy
        case textInput
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
        setupNotifications()
        setupGestures()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar setup
        navigationItem.title = fileURL.lastPathComponent
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
        
        // Search bar
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search in PDF"
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)
        
        // PDF View
        pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = self
        view.addSubview(pdfView)
        
        // Drawing overlay for free drawing
        drawingOverlay = DrawingOverlayView()
        drawingOverlay.backgroundColor = .clear
        drawingOverlay.isUserInteractionEnabled = false
        view.addSubview(drawingOverlay)
        
        // Setup all toolbars
        setupMainToolbar()
        setupEditToolbar()
        setupAnnotationToolbar()
        setupTextToolbar()
        
        // Page navigation
        setupPageNavigation()
        
        // Constraints
        setupConstraints()
        
        // Initially show main toolbar
        showMainToolbar()
    }
    
    private func setupMainToolbar() {
        mainToolbar = UIToolbar()
        mainToolbar.tintColor = .systemBlue
        
        // Create buttons with SF Symbols
        let viewModeButton = UIBarButtonItem(
            image: UIImage(systemName: isVerticalMode ? "doc.text" : "rectangle.grid.1x2"),
            style: .plain,
            target: self,
            action: #selector(toggleViewMode)
        )
        
        let pageButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.text.magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(showPageNavigation)
        )
        
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil.and.outline"),
            style: .plain,
            target: self,
            action: #selector(showEditMode)
        )
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareDocument)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        mainToolbar.items = [viewModeButton, flexSpace, pageButton, flexSpace, editButton, flexSpace, shareButton]
        view.addSubview(mainToolbar)
    }
    
    private func setupEditToolbar() {
        editToolbar = UIToolbar()
        editToolbar.tintColor = .systemBlue
        editToolbar.isHidden = true
        
        let annotateButton = UIBarButtonItem(
            image: UIImage(systemName: "highlighter"),
            style: .plain,
            target: self,
            action: #selector(showAnnotateMode)
        )
        
        let addTextButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat"),
            style: .plain,
            target: self,
            action: #selector(showAddTextMode)
        )
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backToMainToolbar)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        editToolbar.items = [backButton, flexSpace, annotateButton, flexSpace, addTextButton, flexSpace]
        view.addSubview(editToolbar)
    }
    
    private func setupAnnotationToolbar() {
        annotationToolbar = UIToolbar()
        annotationToolbar.tintColor = .systemBlue
        annotationToolbar.isHidden = true
        
        let copyButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(enableCopyMode)
        )
        
        let underlineButton = UIBarButtonItem(
            image: UIImage(systemName: "underline"),
            style: .plain,
            target: self,
            action: #selector(enableUnderlineMode)
        )
        
        let strikethroughButton = UIBarButtonItem(
            image: UIImage(systemName: "strikethrough"),
            style: .plain,
            target: self,
            action: #selector(enableStrikethroughMode)
        )
        
        let highlightButton = UIBarButtonItem(
            image: UIImage(systemName: "highlighter"),
            style: .plain,
            target: self,
            action: #selector(enableHighlightMode)
        )
        
        let drawButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil.tip"),
            style: .plain,
            target: self,
            action: #selector(enableDrawingMode)
        )
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backToEditToolbar)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        annotationToolbar.items = [backButton, flexSpace, copyButton, underlineButton, strikethroughButton, highlightButton, drawButton]
        view.addSubview(annotationToolbar)
    }
    
    private func setupTextToolbar() {
        textToolbar = UIToolbar()
        textToolbar.tintColor = .systemBlue
        textToolbar.isHidden = true
        
        let addTextButton = UIBarButtonItem(
            title: "Add Text",
            style: .plain,
            target: self,
            action: #selector(enableTextInputMode)
        )
        
        let textSizeButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat.size"),
            style: .plain,
            target: self,
            action: #selector(showTextSizeOptions)
        )
        
        let textColorButton = UIBarButtonItem(
            image: UIImage(systemName: "paintbrush"),
            style: .plain,
            target: self,
            action: #selector(showTextColorOptions)
        )
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backToEditToolbar)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        textToolbar.items = [backButton, flexSpace, addTextButton, flexSpace, textSizeButton, flexSpace, textColorButton]
        view.addSubview(textToolbar)
    }
    
    private func setupPageNavigation() {
        pageContainer = UIView()
        pageContainer.backgroundColor = .systemGray6
        pageContainer.layer.cornerRadius = 8
        pageContainer.isHidden = true
        
        let prevButton = UIButton(type: .system)
        prevButton.setTitle("◀", for: .normal)
        prevButton.addTarget(self, action: #selector(previousPage), for: .touchUpInside)
        
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("▶", for: .normal)
        nextButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        
        pageTextField = UITextField()
        pageTextField.borderStyle = .roundedRect
        pageTextField.textAlignment = .center
        pageTextField.keyboardType = .numberPad
        pageTextField.delegate = self
        pageTextField.addTarget(self, action: #selector(pageTextFieldChanged), for: .editingDidEnd)
        
        pageLabel = UILabel()
        pageLabel.text = "of 0"
        pageLabel.textAlignment = .center
        
        [prevButton, pageTextField, pageLabel, nextButton].forEach { pageContainer.addSubview($0) }
        view.addSubview(pageContainer)
        
        // Page container constraints
        pageContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            pageContainer.heightAnchor.constraint(equalToConstant: 40),
            pageContainer.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        // Page navigation buttons constraints
        [prevButton, pageTextField, pageLabel, nextButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: pageContainer.leadingAnchor, constant: 8),
            prevButton.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 30),
            
            pageTextField.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 8),
            pageTextField.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
            pageTextField.widthAnchor.constraint(equalToConstant: 50),
            
            pageLabel.leadingAnchor.constraint(equalTo: pageTextField.trailingAnchor, constant: 4),
            pageLabel.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
            pageLabel.widthAnchor.constraint(equalToConstant: 50),
            
            nextButton.leadingAnchor.constraint(equalTo: pageLabel.trailingAnchor, constant: 8),
            nextButton.trailingAnchor.constraint(equalTo: pageContainer.trailingAnchor, constant: -8),
            nextButton.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupConstraints() {
        [searchBar, pdfView, drawingOverlay, mainToolbar, editToolbar, annotationToolbar, textToolbar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            pdfView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: mainToolbar.topAnchor),
            
            drawingOverlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
            drawingOverlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            drawingOverlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            drawingOverlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor),
        ])
        
        // Toolbar constraints
        for toolbar in [mainToolbar, editToolbar, annotationToolbar, textToolbar] {
            NSLayoutConstraint.activate([
                toolbar!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                toolbar!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                toolbar!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        pdfView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        drawingOverlay.addGestureRecognizer(panGesture)
    }
    
    private func loadPDF() {
        guard let document = PDFDocument(url: fileURL) else {
            showAlert(title: "Error", message: "Could not load PDF document")
            return
        }
        
        pdfDocument = document
        pdfView.document = document
        updatePageInfo()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfViewPageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )
    }
    
    // MARK: - Toolbar Management
    
    private func showMainToolbar() {
        hideAllToolbars()
        mainToolbar.isHidden = false
        currentEditMode = .none
        currentSubMode = .none
        drawingOverlay.isUserInteractionEnabled = false
    }
    
    private func showEditToolbar() {
        hideAllToolbars()
        editToolbar.isHidden = false
        currentEditMode = .none
        currentSubMode = .none
        drawingOverlay.isUserInteractionEnabled = false
    }
    
    private func showAnnotationToolbar() {
        hideAllToolbars()
        annotationToolbar.isHidden = false
        currentEditMode = .annotate
        currentSubMode = .none
        drawingOverlay.isUserInteractionEnabled = false
    }
    
    private func showTextToolbar() {
        hideAllToolbars()
        textToolbar.isHidden = false
        currentEditMode = .addText
        currentSubMode = .none
        drawingOverlay.isUserInteractionEnabled = false
    }
    
    private func hideAllToolbars() {
        mainToolbar.isHidden = true
        editToolbar.isHidden = true
        annotationToolbar.isHidden = true
        textToolbar.isHidden = true
        pageContainer.isHidden = true
    }
    
    // MARK: - Actions
    
    @objc private func dismissView() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
    
    @objc private func shareDocument() {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
    
    @objc private func toggleViewMode() {
        isVerticalMode.toggle()
        
        if isVerticalMode {
            pdfView.displayDirection = .vertical
            pdfView.displayMode = .singlePageContinuous
        } else {
            pdfView.displayDirection = .horizontal
            pdfView.displayMode = .singlePage
        }
        
        // Update button icon
        if let items = mainToolbar.items {
            for item in items {
                if item.image == UIImage(systemName: "doc.text") || item.image == UIImage(systemName: "rectangle.grid.1x2") {
                    item.image = UIImage(systemName: isVerticalMode ? "doc.text" : "rectangle.grid.1x2")
                    break
                }
            }
        }
        
        showTempMessage(isVerticalMode ? "Vertical View" : "Horizontal View")
    }
    
    @objc private func showPageNavigation() {
        pageContainer.isHidden = !pageContainer.isHidden
        updatePageInfo()
    }
    
    @objc private func showEditMode() {
        showEditToolbar()
    }
    
    @objc private func showAnnotateMode() {
        showAnnotationToolbar()
    }
    
    @objc private func showAddTextMode() {
        showTextToolbar()
    }
    
    @objc private func backToMainToolbar() {
        showMainToolbar()
    }
    
    @objc private func backToEditToolbar() {
        showEditToolbar()
    }
    
    // MARK: - Annotation Mode Actions
    
    @objc private func enableCopyMode() {
        currentSubMode = .copy
        showTempMessage("Copy Mode - Tap text to copy")
    }
    
    @objc private func enableUnderlineMode() {
        currentSubMode = .underline
        showTempMessage("Underline Mode - Tap text to underline")
    }
    
    @objc private func enableStrikethroughMode() {
        currentSubMode = .strikethrough
        showTempMessage("Strikethrough Mode - Tap text to strikethrough")
    }
    
    @objc private func enableHighlightMode() {
        currentSubMode = .highlight
        showTempMessage("Highlight Mode - Tap text to highlight")
    }
    
    @objc private func enableDrawingMode() {
        currentSubMode = .drawing
        drawingOverlay.isUserInteractionEnabled = true
        showTempMessage("Drawing Mode - Draw on PDF")
    }
    
    // MARK: - Text Mode Actions
    
    @objc private func enableTextInputMode() {
        currentSubMode = .textInput
        showTempMessage("Text Input Mode - Tap to add text")
    }
    
    @objc private func showTextSizeOptions() {
        let alert = UIAlertController(title: "Text Size", message: "Select text size", preferredStyle: .actionSheet)
        
        let sizes: [CGFloat] = [8, 10, 12, 14, 16, 18, 20, 24, 28, 32]
        
        for size in sizes {
            alert.addAction(UIAlertAction(title: "\(Int(size))pt", style: .default) { _ in
                self.currentTextSize = size
                self.showTempMessage("Text Size: \(Int(size))pt")
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showTextColorOptions() {
        let alert = UIAlertController(title: "Text Color", message: "Select text color", preferredStyle: .actionSheet)
        
        let colors: [(String, UIColor)] = [
            ("Black", .black),
            ("Red", .red),
            ("Blue", .blue),
            ("Green", .green),
            ("Orange", .orange),
            ("Purple", .purple),
            ("Brown", .brown)
        ]
        
        for (name, color) in colors {
            alert.addAction(UIAlertAction(title: name, style: .default) { _ in
                self.currentTextColor = color
                self.showTempMessage("Text Color: \(name)")
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Page Navigation Actions
    
    @objc private func previousPage() {
        pdfView.goToPreviousPage(nil)
        updatePageInfo()
    }
    
    @objc private func nextPage() {
        pdfView.goToNextPage(nil)
        updatePageInfo()
    }
    
    @objc private func pageTextFieldChanged() {
        guard let text = pageTextField.text,
              let pageNumber = Int(text),
              let document = pdfDocument,
              pageNumber > 0,
              pageNumber <= document.pageCount else {
            updatePageInfo()
            return
        }
        
        if let page = document.page(at: pageNumber - 1) {
            pdfView.go(to: page)
            updatePageInfo()
        }
    }
    
    @objc private func pdfViewPageChanged() {
        updatePageInfo()
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: pdfView)
        guard let page = pdfView.page(for: point, nearest: true) else { return }
        let convertedPoint = pdfView.convert(point, to: page)
        
        switch currentSubMode {
        case .copy, .highlight, .underline, .strikethrough:
            selectAndAnnotateText(at: convertedPoint, in: page)
        case .textInput:
            addTextAnnotation(at: convertedPoint, in: page)
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard currentSubMode == .drawing else { return }
        
        let point = gesture.location(in: drawingOverlay)
        
        switch gesture.state {
        case .began:
            drawingOverlay.startDrawing(at: point)
        case .changed:
            drawingOverlay.continueDrawing(to: point)
        case .ended:
            drawingOverlay.endDrawing()
            addDrawingAnnotationToPDF()
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func updatePageInfo() {
        guard let document = pdfDocument,
              let currentPage = pdfView.currentPage else {
            pageTextField.text = "1"
            pageLabel.text = "of 0"
            return
        }
        
        let currentPageIndex = document.index(for: currentPage) + 1
        pageTextField.text = "\(currentPageIndex)"
        pageLabel.text = "of \(document.pageCount)"
    }
    
    private func showTempMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func selectAndAnnotateText(at point: CGPoint, in page: PDFPage) {
        let selection = page.selection(for: CGRect(x: point.x - 20, y: point.y - 10, width: 40, height: 20))
        
        guard let selection = selection else { return }
        
        switch currentSubMode {
        case .copy:
            UIPasteboard.general.string = selection.string
            showTempMessage("Text copied to clipboard")
        case .highlight:
            addHighlightAnnotation(for: selection, color: .yellow)
        case .underline:
            addUnderlineAnnotation(for: selection)
        case .strikethrough:
            addStrikethroughAnnotation(for: selection)
        default:
            break
        }
    }
    
    private func addTextAnnotation(at point: CGPoint, in page: PDFPage) {
        let alert = UIAlertController(title: "Add Text", message: "Enter text to add", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter text"
        }
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            
            let bounds = CGRect(x: point.x, y: point.y, width: 100, height: 20)
            let textAnnotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
            textAnnotation.contents = text
            textAnnotation.font = UIFont.systemFont(ofSize: self.currentTextSize)
            textAnnotation.color = self.currentTextColor
            textAnnotation.fontColor = self.currentTextColor
            
            page.addAnnotation(textAnnotation)
            self.annotationHistory.append(textAnnotation)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func addHighlightAnnotation(for selection: PDFSelection, color: UIColor) {
        guard let page = selection.pages.first else { return }
        
        let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
        highlight.color = color
        highlight.contents = "Highlighted text"
        
        page.addAnnotation(highlight)
        annotationHistory.append(highlight)
        showTempMessage("Text highlighted")
    }
    
    private func addUnderlineAnnotation(for selection: PDFSelection) {
        guard let page = selection.pages.first else { return }
        
        let underline = PDFAnnotation(bounds: selection.bounds(for: page), forType: .underline, withProperties: nil)
        underline.color = UIColor.blue
        underline.contents = "Underlined text"
        
        page.addAnnotation(underline)
        annotationHistory.append(underline)
        showTempMessage("Text underlined")
    }
    
    private func addStrikethroughAnnotation(for selection: PDFSelection) {
        guard let page = selection.pages.first else { return }
        
        let strikethrough = PDFAnnotation(bounds: selection.bounds(for: page), forType: .strikeOut, withProperties: nil)
        strikethrough.color = UIColor.red
        strikethrough.contents = "Strikethrough text"
        
        page.addAnnotation(strikethrough)
        annotationHistory.append(strikethrough)
        showTempMessage("Text struck through")
    }
    
    private func addDrawingAnnotationToPDF() {
            guard let currentPage = pdfView.currentPage,
                  let path = drawingOverlay.getLastPath() else { return }
            
            // Convert drawing overlay coordinates to PDF page coordinates
            let pdfViewBounds = pdfView.bounds
            let pageRect = pdfView.convert(pdfViewBounds, to: currentPage)
            
            // Scale and convert the path to PDF coordinates
            let scaledPath = UIBezierPath()
            let scaleX = pageRect.width / pdfViewBounds.width
            let scaleY = pageRect.height / pdfViewBounds.height
            
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let copiedPath = path.copy() as! UIBezierPath
            copiedPath.apply(transform)
            scaledPath.append(copiedPath)

            
            // Create ink annotation
            let inkAnnotation = PDFAnnotation(bounds: scaledPath.bounds, forType: .ink, withProperties: nil)
            inkAnnotation.color = UIColor.red
            inkAnnotation.border = PDFBorder()
            inkAnnotation.border?.lineWidth = 2.0
            
            // Add the path to the ink annotation
            let bezierPaths: [UIBezierPath] = [scaledPath]

            for path in bezierPaths {
                inkAnnotation.add(path)
            }

            
            currentPage.addAnnotation(inkAnnotation)
            annotationHistory.append(inkAnnotation)
            
            // Clear the drawing overlay
            drawingOverlay.removeLastPath()
            showTempMessage("Drawing added to PDF")
        }
        
        private func performSearch() {
            guard let searchText = searchBar.text, !searchText.isEmpty,
                  let document = pdfDocument else { return }
            
            searchResults.removeAll()
            currentSearchIndex = 0
            
            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                let selections = document.findString(searchText, withOptions: .caseInsensitive)
                searchResults.append(contentsOf: selections)
            }
            
            if !searchResults.isEmpty {
                navigateToSearchResult(at: 0)
                updateSearchResultsDisplay()
            } else {
                showTempMessage("No results found")
            }
        }
        
        private func navigateToSearchResult(at index: Int) {
            guard index >= 0 && index < searchResults.count else { return }
            
            let selection = searchResults[index]
            guard let page = selection.pages.first else { return }
            
            pdfView.go(to: selection)
            pdfView.setCurrentSelection(selection, animate: true)
            currentSearchIndex = index
        }
        
        private func updateSearchResultsDisplay() {
            if searchResults.isEmpty {
                searchBar.placeholder = "Search in PDF"
            } else {
                searchBar.placeholder = "Result \(currentSearchIndex + 1) of \(searchResults.count)"
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }

    // MARK: - UISearchBarDelegate

    extension EnhancedPDFViewController: UISearchBarDelegate {
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            performSearch()
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            searchResults.removeAll()
            pdfView.clearSelection()
            searchBar.placeholder = "Search in PDF"
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.isEmpty {
                searchResults.removeAll()
                pdfView.clearSelection()
                searchBar.placeholder = "Search in PDF"
            }
        }
    }

    // MARK: - UITextFieldDelegate

    extension EnhancedPDFViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            if textField == pageTextField {
                pageTextFieldChanged()
            }
            return true
        }
    }

    // MARK: - PDFViewDelegate

    extension EnhancedPDFViewController: PDFViewDelegate {
        func pdfViewWillClickOnLink(_ sender: PDFView, with url: URL) {
            let alert = UIAlertController(title: "Open Link", message: "Do you want to open this link?\n\(url.absoluteString)", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Open", style: .default) { _ in
                UIApplication.shared.open(url)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
        }
        
        func pdfViewParentViewController(_ sender: PDFView) -> UIViewController {
            return self
        }
    }

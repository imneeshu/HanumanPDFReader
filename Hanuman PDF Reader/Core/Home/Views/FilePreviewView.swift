//  FilePreviewView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 07/06/25.

import SwiftUI
import UIKit
import PDFKit

struct FilePreviewView: UIViewControllerRepresentable {
    let fileURL: URL
    let onDismiss: (() -> Void)?
    
    init(fileURL: URL, onDismiss: (() -> Void)? = nil) {
        self.fileURL = fileURL
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        context.coordinator.parentViewController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if context.coordinator.shouldPresentDocument {
            DispatchQueue.main.async {
                context.coordinator.prepareAndPresentDocument(from: uiViewController)
            }
            context.coordinator.shouldPresentDocument = false
        }
    }


    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL, onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
        private let originalFileURL: URL
        private var localFileURL: URL?
        private var documentInteractionController: UIDocumentInteractionController?
        private let onDismiss: (() -> Void)?
        weak var parentViewController: UIViewController?
        var shouldPresentDocument = true
        private var downloadTask: URLSessionDownloadTask?

        init(fileURL: URL, onDismiss: (() -> Void)?) {
            self.originalFileURL = fileURL
            self.onDismiss = onDismiss
            super.init()
        }

        func prepareAndPresentDocument(from viewController: UIViewController) {
            // Check if it's a PDF file for enhanced preview
            if originalFileURL.pathExtension.lowercased() == "pdf" {
                presentEnhancedPDFPreview(from: viewController)
                return
            }
            
            // First, check if file is already local
            if FileManager.default.fileExists(atPath: originalFileURL.path) {
                presentDocument(with: originalFileURL, from: viewController)
                return
            }
            
            // Check if it's an iCloud file and handle accordingly
            handleiCloudFile(from: viewController)
        }
        
        private func presentEnhancedPDFPreview(from viewController: UIViewController) {
            // First ensure we have a local copy of the PDF
            if FileManager.default.fileExists(atPath: originalFileURL.path) {
                let pdfViewController = EnhancedPDFViewController(fileURL: originalFileURL)
                pdfViewController.onDismiss = onDismiss
                let navController = UINavigationController(rootViewController: pdfViewController)
                navController.modalPresentationStyle = .fullScreen
                viewController.present(navController, animated: true)
                return
            }
            
            // Handle iCloud or remote files
            handleiCloudFileForPDF(from: viewController)
        }
        
        private func handleiCloudFileForPDF(from viewController: UIViewController) {
            do {
                let resourceValues = try originalFileURL.resourceValues(forKeys: [
                    .isUbiquitousItemKey,
                    .ubiquitousItemDownloadingStatusKey
                ])
                
                let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                
                if isUbiquitous {
                    let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                    let isDownloaded = (downloadStatus == .current)
                    
                    if isDownloaded {
                        let pdfViewController = EnhancedPDFViewController(fileURL: originalFileURL)
                        pdfViewController.onDismiss = onDismiss
                        let navController = UINavigationController(rootViewController: pdfViewController)
                        navController.modalPresentationStyle = .fullScreen
                        viewController.present(navController, animated: true)
                    } else {
                        downloadFromiCloudForPDF(from: viewController)
                    }
                } else {
                    copyToLocalDirectoryForPDF(from: viewController)
                }
            } catch {
                copyToLocalDirectoryForPDF(from: viewController)
            }
        }
        
        private func downloadFromiCloudForPDF(from viewController: UIViewController) {
            showLoadingIndicator(on: viewController)
            
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: originalFileURL)
                monitorDownloadProgressForPDF(from: viewController)
            } catch {
                hideLoadingIndicator(on: viewController)
                showError("Failed to start download: \(error.localizedDescription)", on: viewController)
            }
        }
        
        private func monitorDownloadProgressForPDF(from viewController: UIViewController) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var attempts = 0
                let maxAttempts = 30
                
                while attempts < maxAttempts {
                    do {
                        let resourceValues = try self.originalFileURL.resourceValues(forKeys: [
                            .ubiquitousItemDownloadingStatusKey
                        ])
                        
                        let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                        let isDownloaded = (downloadStatus == .current)
                        
                        if isDownloaded {
                            DispatchQueue.main.async {
                                self.hideLoadingIndicator(on: viewController)
                                let pdfViewController = EnhancedPDFViewController(fileURL: self.originalFileURL)
                                pdfViewController.onDismiss = self.onDismiss
                                let navController = UINavigationController(rootViewController: pdfViewController)
                                navController.modalPresentationStyle = .fullScreen
                                viewController.present(navController, animated: true)
                            }
                            return
                        }
                        
                        if downloadStatus == .notDownloaded {
                            DispatchQueue.main.async {
                                self.hideLoadingIndicator(on: viewController)
                                self.showError("Download failed or was cancelled", on: viewController)
                            }
                            return
                        }
                        
                    } catch {
                        print("Error monitoring download: \(error)")
                    }
                    
                    attempts += 1
                    Thread.sleep(forTimeInterval: 0.5)
                }
                
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(on: viewController)
                    self.showError("Download timeout. Please try again.", on: viewController)
                }
            }
        }
        
        private func copyToLocalDirectoryForPDF(from viewController: UIViewController) {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                showError("Cannot access documents directory", on: viewController)
                return
            }
            
            let fileName = originalFileURL.lastPathComponent
            let localURL = documentsDirectory.appendingPathComponent("ImportedFiles").appendingPathComponent(fileName)
            
            do {
                try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), 
                                                       withIntermediateDirectories: true, 
                                                       attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
            }
            
            showLoadingIndicator(on: viewController)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    
                    try FileManager.default.copyItem(at: self?.originalFileURL ?? URL(fileURLWithPath: ""), to: localURL)
                    
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator(on: viewController)
                        self?.localFileURL = localURL
                        let pdfViewController = EnhancedPDFViewController(fileURL: localURL)
                        pdfViewController.onDismiss = self?.onDismiss
                        let navController = UINavigationController(rootViewController: pdfViewController)
                        navController.modalPresentationStyle = .fullScreen
                        viewController.present(navController, animated: true)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator(on: viewController)
                        self?.showError("Failed to copy file: \(error.localizedDescription)", on: viewController)
                    }
                }
            }
        }
        
        private func handleiCloudFile(from viewController: UIViewController) {
            do {
                let resourceValues = try originalFileURL.resourceValues(forKeys: [
                    .isUbiquitousItemKey,
                    .ubiquitousItemDownloadingStatusKey
                ])
                
                let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                
                if isUbiquitous {
                    let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                    let isDownloaded = (downloadStatus == .current)
                    
                    print("iCloud file detected. Downloaded: \(isDownloaded), Status: \(downloadStatus?.rawValue ?? "unknown")")
                    
                    if isDownloaded {
                        presentDocument(with: originalFileURL, from: viewController)
                    } else {
                        downloadFromiCloud(from: viewController)
                    }
                } else {
                    copyToLocalDirectory(from: viewController)
                }
            } catch {
                print("Error checking iCloud status: \(error)")
                copyToLocalDirectory(from: viewController)
            }
        }
        
        private func downloadFromiCloud(from viewController: UIViewController) {
            showLoadingIndicator(on: viewController)
            
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: originalFileURL)
                monitorDownloadProgress(from: viewController)
            } catch {
                hideLoadingIndicator(on: viewController)
                showError("Failed to start download: \(error.localizedDescription)", on: viewController)
            }
        }
        
        private func monitorDownloadProgress(from viewController: UIViewController) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var attempts = 0
                let maxAttempts = 30
                
                while attempts < maxAttempts {
                    do {
                        let resourceValues = try self.originalFileURL.resourceValues(forKeys: [
                            .ubiquitousItemDownloadingStatusKey
                        ])
                        
                        let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                        let isDownloaded = (downloadStatus == .current)
                        
                        if isDownloaded {
                            DispatchQueue.main.async {
                                self.hideLoadingIndicator(on: viewController)
                                self.presentDocument(with: self.originalFileURL, from: viewController)
                            }
                            return
                        }
                        
                        if downloadStatus == .notDownloaded {
                            DispatchQueue.main.async {
                                self.hideLoadingIndicator(on: viewController)
                                self.showError("Download failed or was cancelled", on: viewController)
                            }
                            return
                        }
                        
                    } catch {
                        print("Error monitoring download: \(error)")
                    }
                    
                    attempts += 1
                    Thread.sleep(forTimeInterval: 0.5)
                }
                
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(on: viewController)
                    self.showError("Download timeout. Please try again.", on: viewController)
                }
            }
        }
        
        private func copyToLocalDirectory(from viewController: UIViewController) {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                showError("Cannot access documents directory", on: viewController)
                return
            }
            
            let fileName = originalFileURL.lastPathComponent
            let localURL = documentsDirectory.appendingPathComponent("ImportedFiles").appendingPathComponent(fileName)
            
            do {
                try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), 
                                                       withIntermediateDirectories: true, 
                                                       attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
            }
            
            showLoadingIndicator(on: viewController)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    
                    try FileManager.default.copyItem(at: self?.originalFileURL ?? URL(fileURLWithPath: ""), to: localURL)
                    
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator(on: viewController)
                        self?.localFileURL = localURL
                        self?.presentDocument(with: localURL, from: viewController)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator(on: viewController)
                        self?.showError("Failed to copy file: \(error.localizedDescription)", on: viewController)
                    }
                }
            }
        }
        
        private func presentDocument(with url: URL, from viewController: UIViewController) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                guard FileManager.default.fileExists(atPath: url.path) else {
                    self.showError("File not found at path: \(url.path)", on: viewController)
                    return
                }
                
                let documentController = UIDocumentInteractionController(url: url)
                documentController.delegate = self
                
                self.documentInteractionController = documentController
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !documentController.presentPreview(animated: true) {
                        self.showError("Cannot preview this file type", on: viewController)
                    }
                }
            }
        }
        
        // MARK: - UI Helper Methods
        
        private func showLoadingIndicator(on viewController: UIViewController) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: nil, message: "Loading file...", preferredStyle: .alert)
                
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating()
                
                alert.setValue(loadingIndicator, forKey: "accessoryView")
                viewController.present(alert, animated: true)
            }
        }
        
        private func hideLoadingIndicator(on viewController: UIViewController) {
            DispatchQueue.main.async {
                if let presentedAlert = viewController.presentedViewController as? UIAlertController {
                    presentedAlert.dismiss(animated: true)
                }
            }
        }
        
        private func showError(_ message: String, on viewController: UIViewController) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    self?.onDismiss?()
                })
                viewController.present(alert, animated: true)
            }
        }

        // MARK: - UIDocumentInteractionControllerDelegate

        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            return parentViewController ?? findRootViewController() ?? UIViewController()
        }

        func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
            documentInteractionController = nil
            DispatchQueue.main.async {
                self.onDismiss?()
            }
        }
        
        func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
            documentInteractionController = nil
            DispatchQueue.main.async {
                self.onDismiss?()
            }
        }
        
        private func findRootViewController() -> UIViewController? {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.rootViewController
            }
            return nil
        }
        
        deinit {
            downloadTask?.cancel()
        }
    }
}





import UIKit
import PDFKit

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
    private var toolbar: UIToolbar!
    private var pageLabel: UILabel!
    private var pageTextField: UITextField!
    private var currentEditMode: EditMode = .none
    private var isVerticalMode = true
    private var searchResults: [PDFSelection] = []
    private var currentSearchIndex = 0
    private var drawingOverlay: DrawingOverlayView!
    private var annotationHistory: [PDFAnnotation] = []
    
    var onDismiss: (() -> Void)?
    
    enum EditMode {
        case none
        case highlight
        case underline
        case strikethrough
        case drawing
        case textSelection
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareDocument))
        
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
        
        // Toolbar
        setupToolbar()
        
        // Page navigation
        setupPageNavigation()
        
        // Constraints
        setupConstraints()
    }
    
    private func setupToolbar() {
        toolbar = UIToolbar()
        
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditMenu))
        let viewModeButton = UIBarButtonItem(title: "View", style: .plain, target: self, action: #selector(toggleViewMode))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let zoomInButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(zoomIn))
        let zoomOutButton = UIBarButtonItem(title: "−", style: .plain, target: self, action: #selector(zoomOut))
        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoLastAnnotation))
        
        toolbar.items = [editButton, flexSpace, viewModeButton, flexSpace, undoButton, zoomOutButton, zoomInButton]
        view.addSubview(toolbar)
    }
    
    private func setupPageNavigation() {
        let pageContainer = UIView()
        pageContainer.backgroundColor = .systemGray6
        pageContainer.layer.cornerRadius = 8
        
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
            pageContainer.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -10),
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
        [searchBar, pdfView, drawingOverlay, toolbar].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            pdfView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            
            drawingOverlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
            drawingOverlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            drawingOverlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            drawingOverlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor),
            
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard currentEditMode != .none else { return }
        
        let point = gesture.location(in: pdfView)
        guard let page = pdfView.page(for: point, nearest: true) else { return }
        
        let convertedPoint = pdfView.convert(point, to: page)
        
        switch currentEditMode {
        case .textSelection:
            selectTextAt(point: convertedPoint, in: page)
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard currentEditMode == .drawing else { return }
        
        let point = gesture.location(in: drawingOverlay)
        
        switch gesture.state {
        case .began:
            drawingOverlay.startDrawing(at: point)
        case .changed:
            drawingOverlay.continueDrawing(to: point)
        case .ended:
            drawingOverlay.endDrawing()
            // Convert drawing to PDF annotation
            addDrawingAnnotationToPDF()
        default:
            break
        }
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
    
    @objc private func toggleEditMenu() {
        let alert = UIAlertController(title: "Edit Mode", message: "Select editing tool", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Select Text", style: .default) { _ in
            self.currentEditMode = .textSelection
            self.showEditModeIndicator("Text Selection Mode")
            self.drawingOverlay.isUserInteractionEnabled = false
        })
        
        alert.addAction(UIAlertAction(title: "Highlight", style: .default) { _ in
            self.currentEditMode = .highlight
            self.showEditModeIndicator("Highlight Mode")
            self.drawingOverlay.isUserInteractionEnabled = false
        })
        
        alert.addAction(UIAlertAction(title: "Underline", style: .default) { _ in
            self.currentEditMode = .underline
            self.showEditModeIndicator("Underline Mode")
            self.drawingOverlay.isUserInteractionEnabled = false
        })
        
        alert.addAction(UIAlertAction(title: "Strikethrough", style: .default) { _ in
            self.currentEditMode = .strikethrough
            self.showEditModeIndicator("Strikethrough Mode")
            self.drawingOverlay.isUserInteractionEnabled = false
        })
        
        alert.addAction(UIAlertAction(title: "Draw", style: .default) { _ in
            self.currentEditMode = .drawing
            self.showEditModeIndicator("Drawing Mode")
            self.drawingOverlay.isUserInteractionEnabled = true
        })
        
        alert.addAction(UIAlertAction(title: "Exit Edit Mode", style: .destructive) { _ in
            self.currentEditMode = .none
            self.showEditModeIndicator("View Mode")
            self.drawingOverlay.isUserInteractionEnabled = false
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.permittedArrowDirections = .up
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 50, width: 0, height: 0)
        }
        
        present(alert, animated: true)
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
        
        showEditModeIndicator(isVerticalMode ? "Vertical View" : "Horizontal View")
    }
    
    @objc private func zoomIn() {
        pdfView.scaleFactor *= 1.2
    }
    
    @objc private func zoomOut() {
        pdfView.scaleFactor /= 1.2
    }
    
    @objc private func undoLastAnnotation() {
        if !annotationHistory.isEmpty {
            let lastAnnotation = annotationHistory.removeLast()
            lastAnnotation.page?.removeAnnotation(lastAnnotation)
        } else {
            drawingOverlay.removeLastPath()
        }
    }
    
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
    
    private func showEditModeIndicator(_ message: String) {
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
    
    private func performSearch(_ searchText: String) {
        guard let document = pdfDocument else { return }
        
        searchResults.removeAll()
        currentSearchIndex = 0
        
        // Use document-level search instead of page-level
        let selections = document.findString(searchText, withOptions: .caseInsensitive)
        searchResults.append(contentsOf: selections)
        
        if !searchResults.isEmpty {
            highlightSearchResult(at: 0)
        }
    }
    
    private func highlightSearchResult(at index: Int) {
        guard index < searchResults.count else { return }
        
        let selection = searchResults[index]
        pdfView.setCurrentSelection(selection, animate: true)
        pdfView.go(to: selection)
    }
    
    private func selectTextAt(point: CGPoint, in page: PDFPage) {
        // Create a selection around the tapped point
        let selection = page.selection(for: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
        
        if let selection = selection {
            pdfView.setCurrentSelection(selection, animate: true)
            
            // Show annotation options
            showAnnotationOptions(for: selection)
        }
    }
    
    private func showAnnotationOptions(for selection: PDFSelection) {
        let alert = UIAlertController(title: "Annotate", message: "Choose annotation type", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Highlight", style: .default) { _ in
            self.addHighlightAnnotation(for: selection, color: .yellow)
        })
        
        alert.addAction(UIAlertAction(title: "Underline", style: .default) { _ in
            self.addUnderlineAnnotation(for: selection)
        })
        
        alert.addAction(UIAlertAction(title: "Strikethrough", style: .default) { _ in
            self.addStrikethroughAnnotation(for: selection)
        })
        
        alert.addAction(UIAlertAction(title: "Note", style: .default) { _ in
            self.addNoteAnnotation(for: selection)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = pdfView
            popover.sourceRect = CGRect(x: pdfView.bounds.midX, y: pdfView.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func addHighlightAnnotation(for selection: PDFSelection, color: UIColor) {
        guard let page = selection.pages.first else { return }
        
        let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
        highlight.color = color
        highlight.contents = "Highlighted text"
        
        page.addAnnotation(highlight)
        annotationHistory.append(highlight)
    }
    
    private func addUnderlineAnnotation(for selection: PDFSelection) {
        guard let page = selection.pages.first else { return }
        
        let underline = PDFAnnotation(bounds: selection.bounds(for: page), forType: .underline, withProperties: nil)
        underline.color = UIColor.blue
        underline.contents = "Underlined text"
        
        page.addAnnotation(underline)
        annotationHistory.append(underline)
    }
    
    private func addStrikethroughAnnotation(for selection: PDFSelection) {
        guard let page = selection.pages.first else { return }
        
        let strikethrough = PDFAnnotation(bounds: selection.bounds(for: page), forType: .strikeOut, withProperties: nil)
        strikethrough.color = UIColor.red
        strikethrough.contents = "Strikethrough text"
        
        page.addAnnotation(strikethrough)
        annotationHistory.append(strikethrough)
    }
    
    private func addNoteAnnotation(for selection: PDFSelection) {
        let alert = UIAlertController(title: "Add Note", message: "Enter your note", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter note text"
        }
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let noteText = alert.textFields?.first?.text,
                  !noteText.isEmpty,
                  let page = selection.pages.first else { return }
            
            let bounds = selection.bounds(for: page)
            let note = PDFAnnotation(bounds: bounds, forType: .text, withProperties: nil)
            note.contents = noteText
            note.iconType = .note
            note.color = UIColor.orange
            
            page.addAnnotation(note)
            self.annotationHistory.append(note)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func addDrawingAnnotationToPDF() {
        guard let currentPage = pdfView.currentPage,
              let path = drawingOverlay.getLastPath() else { return }
        
        // Convert the drawing path to PDF coordinate system
        let pdfBounds = pdfView.convert(path.bounds, to: currentPage)
        
        // Create ink annotation with proper path data
        let pathArray = convertBezierPathToInkPaths(path, in: currentPage)
        
        let inkAnnotation = PDFAnnotation(bounds: pdfBounds, forType: .ink, withProperties: [
            "InkList": pathArray
        ])
        inkAnnotation.color = UIColor.red
        
        currentPage.addAnnotation(inkAnnotation)
        annotationHistory.append(inkAnnotation)
        
        // Clear the drawing overlay
        drawingOverlay.clearDrawing()
    }
    
    private func convertBezierPathToInkPaths(_ bezierPath: UIBezierPath, in page: PDFPage) -> [[NSValue]] {
        var pathArray: [[NSValue]] = []
        var currentPathSegment: [NSValue] = []
        
        // Struct to pass necessary context
        struct Context {
            var pdfView: PDFView
            var page: PDFPage
            var currentPathSegment: UnsafeMutablePointer<[NSValue]>
            var pathArray: UnsafeMutablePointer<[[NSValue]]>
        }
        
        // Create context
        var currentSegment = currentPathSegment
        var allPaths = pathArray
        var context = Context(pdfView: self.pdfView, page: page, currentPathSegment: &currentSegment, pathArray: &allPaths)
        
        let contextPointer = UnsafeMutableRawPointer(&context)
        
        bezierPath.cgPath.apply(info: contextPointer) { (info, elementPointer) in
            guard let info = info else { return }
            
            let context = info.assumingMemoryBound(to: Context.self).pointee
            let type = elementPointer.pointee.type
            let points = elementPointer.pointee.points
            
            switch type {
            case .moveToPoint:
                if !context.currentPathSegment.pointee.isEmpty {
                    context.pathArray.pointee.append(context.currentPathSegment.pointee)
                    context.currentPathSegment.pointee.removeAll()
                }
                let convertedPoint = context.pdfView.convert(points[0], to: context.page)
                context.currentPathSegment.pointee.append(NSValue(cgPoint: convertedPoint))
                
            case .addLineToPoint:
                let convertedPoint = context.pdfView.convert(points[0], to: context.page)
                context.currentPathSegment.pointee.append(NSValue(cgPoint: convertedPoint))
                
            case .addQuadCurveToPoint, .addCurveToPoint:
                let count = type == .addQuadCurveToPoint ? 2 : 3
                let convertedPoint = context.pdfView.convert(points[count - 1], to: context.page)
                context.currentPathSegment.pointee.append(NSValue(cgPoint: convertedPoint))
                
            case .closeSubpath:
                break
                
            @unknown default:
                break
            }
        }

        // Append the final segment
        if !currentSegment.isEmpty {
            allPaths.append(currentSegment)
        }
        
        return allPaths
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - PDFView Delegate

extension EnhancedPDFViewController: PDFViewDelegate {
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - UISearchBar Delegate

extension EnhancedPDFViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults.removeAll()
            pdfView.setCurrentSelection(nil, animate: false)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        performSearch(searchText)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchResults.removeAll()
        pdfView.setCurrentSelection(nil, animate: false)
    }
}

// MARK: - UITextField Delegate

extension EnhancedPDFViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        pageTextFieldChanged()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
}


// MARK: - Simplified Direct PDF View
struct DirectPDFView: UIViewControllerRepresentable {
    let fileURL: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let pdfViewController = EnhancedPDFViewController(fileURL: fileURL)
        pdfViewController.onDismiss = onDismiss
        return UINavigationController(rootViewController: pdfViewController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }
}

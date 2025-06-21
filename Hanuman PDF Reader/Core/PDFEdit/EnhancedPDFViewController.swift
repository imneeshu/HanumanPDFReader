//
//  EnhancedPDFViewController.swift
//  Hanuman PDF Readers
//
//  Created by Neeshu Kumar on 16/06/25.
//
//  Localization keys added or changed:
//  "Add Text" (Add text alert title)
//  "Enter text" (Add text alert placeholder)
//  "Add" (Add button title)
//  "Cancel" (Cancel button title)
//  "Text Size" (Text size option title)
//  "Select text size" (Text size option message)
//  "%dpt" (Text size option subtitle format)
//  "Text Color" (Text color option title)
//  "Select text color" (Text color option message)
//  "Black" (Text color option name)
//  "Red" (Text color option name)
//  "Blue" (Text color option name)
//  "Green" (Text color option name)
//  "Orange" (Text color option name)
//  "Purple" (Text color option name)
//  "Yellow" (Text color option name)
//  "Pink" (Text color option name)
//  "Copy Mode - Select text to copy" (Copy mode message)
//  "Underline Mode - Select text to underline" (Underline mode message)
//  "Strikethrough Mode - Select text to strikethrough" (Strikethrough mode message)
//  "Highlight Mode - Select text to highlight" (Highlight mode message)
//  "Drawing Mode - Draw on PDF" (Drawing mode message)
//  "Exited Drawing Mode" (Exit drawing mode message)
//  "Tap anywhere to add text" (Text input mode message)
//  "Vertical View" (Vertical view toggle message)
//  "Horizontal View" (Horizontal view toggle message)
//  "Search in PDF" (Search bar placeholder)
//  "Error" (Error alert title)
//  "Could not load PDF document" (PDF load error message)
//  "OK" (OK button title)
//  "Text copied" (Copy confirmation message)
//  "Text size: %dpt" (Text size changed message)
//  "Text color: %@" (Text color changed message)
//  "of %d" (Page count label format)

import UIKit
import PDFKit
import SwiftUI


// MARK: - Annotation Command for Undo/Redo
class AnnotationCommand {
    let annotation: PDFAnnotation
    let page: PDFPage
    let isAdd: Bool // true for add, false for remove
    
    init(annotation: PDFAnnotation, page: PDFPage, isAdd: Bool) {
        self.annotation = annotation
        self.page = page
        self.isAdd = isAdd
    }
    
    func execute() {
        if isAdd {
            page.addAnnotation(annotation)
        } else {
            page.removeAnnotation(annotation)
        }
    }
    
    func undo() {
        if isAdd {
            page.removeAnnotation(annotation)
        } else {
            page.addAnnotation(annotation)
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
    private var isVerticalMode = true
    
    // Search & annotations
    private var searchResults: [PDFSelection] = []
    private var currentSearchIndex = 0
    private var drawingOverlay: DrawingOverlayView!
    
    // Text properties
    private var currentTextSize: CGFloat = 12.0
    private var currentTextColor: UIColor = .label
    
    // Annotation selection tracking
    private var selectionStartPoint: CGPoint?
    private var currentSelection: PDFSelection?
    private var isSelecting = false
    
    // Tracking overlays for movable text annotations
    private var textAnnotationOverlays: [PDFAnnotation: TextAnnotationOverlayView] = [:]
    
    // Undo/Redo system
    private var undoStack: [AnnotationCommand] = []
    private var redoStack: [AnnotationCommand] = []
    
    // Drawing options (colors and thicknesses)
    private let drawingColors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemYellow, .black]
    private let drawingThicknesses: [CGFloat] = [1, 3, 5, 8, 12]
    
    private var selectedColor: UIColor = .systemRed
    private var selectedThickness: CGFloat = 3
    
    private var drawingOptionsCollectionView: UICollectionView!
    private var drawToggleButton: UIBarButtonItem!
    
    // Toolbar buttons for annotation mode to track selected button
    private var copyButton: UIBarButtonItem!
    private var underlineButton: UIBarButtonItem!
    private var strikethroughButton: UIBarButtonItem!
    private var highlightButton: UIBarButtonItem!
    
    // Currently selected annotation toolbar button
    private var selectedAnnotationButton: UIBarButtonItem?
    
    // [FIX] Drawing now handled by gesture attached to drawingOverlay, not pdfView.
    private var drawingPanGesture: UIPanGestureRecognizer!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextAnnotationOverlayDeleted(_:)), name: .textAnnotationOverlayDidDelete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadTextAnnotationOverlays), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadTextAnnotationOverlays), name: .PDFViewPageChanged, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        searchBar.placeholder = NSLocalizedString("Search in PDF", comment: "Search bar placeholder")
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)
        
        // PDF View
        pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = self
        pdfView.backgroundColor = .systemBackground
        view.addSubview(pdfView)
        
        // Drawing overlay for free drawing
        drawingOverlay = DrawingOverlayView()
        drawingOverlay.backgroundColor = .clear
        drawingOverlay.isUserInteractionEnabled = false
        drawingOverlay.strokeColor = selectedColor
        drawingOverlay.strokeWidth = selectedThickness
        view.addSubview(drawingOverlay)
        
        // Setup all toolbars
        setupMainToolbar()
        setupEditToolbar()
        setupAnnotationToolbar()
        setupTextToolbar()
        
        // Setup drawing options collection view
        setupDrawingOptionsCollectionView()
        
        // Page navigation
        setupPageNavigation()
        
        // Constraints
        setupConstraints()
        
        // Initially show main toolbar
        showMainToolbar()
    }
    
    private func setupDrawingOptionsCollectionView() {
        // Layout with two sections: colors and thicknesses
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            // Item size
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(40), heightDimension: .absolute(40))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            
            // Group size and group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(48))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(8)
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
            return section
        }
        
        drawingOptionsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        drawingOptionsCollectionView.backgroundColor = .secondarySystemBackground
        drawingOptionsCollectionView.showsHorizontalScrollIndicator = false
        drawingOptionsCollectionView.register(DrawingOptionCell.self, forCellWithReuseIdentifier: DrawingOptionCell.reuseIdentifier)
        drawingOptionsCollectionView.dataSource = self
        drawingOptionsCollectionView.delegate = self
        drawingOptionsCollectionView.isHidden = true
        view.addSubview(drawingOptionsCollectionView)
        
        drawingOptionsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            drawingOptionsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawingOptionsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            drawingOptionsCollectionView.bottomAnchor.constraint(equalTo: annotationToolbar.topAnchor),
            drawingOptionsCollectionView.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupMainToolbar() {
        mainToolbar = UIToolbar()
        mainToolbar.tintColor = navyUIKit
        mainToolbar.backgroundColor = .secondarySystemBackground
        
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
        editToolbar.tintColor = navyUIKit
        editToolbar.backgroundColor = .secondarySystemBackground
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
        annotationToolbar.tintColor = navyUIKit
        annotationToolbar.backgroundColor = .secondarySystemBackground
        annotationToolbar.isHidden = true
        
        copyButton = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(enableCopyMode)
        )
        
        underlineButton = UIBarButtonItem(
            image: UIImage(systemName: "underline"),
            style: .plain,
            target: self,
            action: #selector(enableUnderlineMode)
        )
        
        strikethroughButton = UIBarButtonItem(
            image: UIImage(systemName: "strikethrough"),
            style: .plain,
            target: self,
            action: #selector(enableStrikethroughMode)
        )
        
        highlightButton = UIBarButtonItem(
            image: UIImage(systemName: "highlighter"),
            style: .plain,
            target: self,
            action: #selector(enableHighlightMode)
        )
        
        // Draw toggle button
        drawToggleButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil.tip"),
            style: .plain,
            target: self,
            action: #selector(toggleDrawingMode)
        )
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backToEditToolbar)
        )
        
        let undoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(undoAnnotation)
        )
        
        let redoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.forward"),
            style: .plain,
            target: self,
            action: #selector(redoAnnotation)
        )
        
        // Create fixed space items for padding between icons
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 20 // Adjust this value to control spacing
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Helper function to create fixed space
        func createFixedSpace(_ width: CGFloat = 20) -> UIBarButtonItem {
            let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            space.width = width
            return space
        }
        
        annotationToolbar.items = [
            backButton,
            flexSpace,
            copyButton,
            createFixedSpace(),
            underlineButton,
            createFixedSpace(),
            strikethroughButton,
            createFixedSpace(),
            highlightButton,
            createFixedSpace(),
            drawToggleButton,
            flexSpace,
            undoButton,
            createFixedSpace(),
            redoButton
        ]
        
        view.addSubview(annotationToolbar)
    }
    
    private func setupTextToolbar() {
        textToolbar = UIToolbar()
        textToolbar.tintColor = navyUIKit
        textToolbar.backgroundColor = .secondarySystemBackground
        textToolbar.isHidden = true
        
        let addTextButton = UIBarButtonItem(
            title: NSLocalizedString("Add Text", comment: "Add text alert title"),
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
        pageContainer.backgroundColor = UIColor.secondarySystemBackground
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
        pageLabel.text = NSLocalizedString("of 0", comment: "Page count label")
        pageLabel.textAlignment = .center
        pageLabel.textColor = .label
        
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
        tapGesture.delegate = self
        pdfView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        pdfView.addGestureRecognizer(panGesture)
        
        // [FIX] Drawing now handled by gesture attached to drawingOverlay, not pdfView.
        let drawingPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrawingPan(_:)))
        drawingPanGesture.delegate = self
        drawingPanGesture.isEnabled = false // Only enable when in drawing mode
        self.drawingPanGesture = drawingPanGesture
        drawingOverlay.addGestureRecognizer(drawingPanGesture)
    }
    
    private func loadPDF() {
        guard let document = PDFDocument(url: fileURL) else {
            showAlert(title: NSLocalizedString("Error", comment: "Error alert title"), message: NSLocalizedString("Could not load PDF document", comment: "PDF load error message"))
            return
        }
        
        pdfDocument = document
        pdfView.document = document
        updatePageInfo()
        loadTextAnnotationOverlays()
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
        drawingOptionsCollectionView.isHidden = true
        mainToolbar.isHidden = false
        currentEditMode = .none
        currentSubMode = .none
//        drawingOverlay.isUserInteractionEnabled = false
//        drawingPanGesture.isEnabled = false
        clearSelection()
        clearAnnotationToolbarSelection()
    }
    
    private func showEditToolbar() {
        hideAllToolbars()
        drawingOptionsCollectionView.isHidden = true
        editToolbar.isHidden = false
        currentEditMode = .none
        currentSubMode = .none
        drawingOverlay.isUserInteractionEnabled = false
        drawingPanGesture.isEnabled = false
        clearSelection()
        clearAnnotationToolbarSelection()
    }
    
    private func showAnnotationToolbar() {
        hideAllToolbars()
        annotationToolbar.isHidden = false
        drawingOptionsCollectionView.isHidden = currentSubMode != .drawing
        currentEditMode = .annotate
        
        if currentSubMode == .none {
            currentSubMode = .highlight
            selectAnnotationToolbarButton(highlightButton)
            drawingPanGesture.isEnabled = false
            drawingOverlay.isUserInteractionEnabled = false
        } else if currentSubMode == .drawing {
            drawingOverlay.isUserInteractionEnabled = true
            drawingPanGesture.isEnabled = true
            updateDrawingOverlayAppearance()
            selectAnnotationToolbarButton(nil)
        } else {
            updateAnnotationToolbarSelection()
        }
        if currentSubMode != .drawing {
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
        }
        clearSelection()
    }
    
    private func showTextToolbar() {
        hideAllToolbars()
        drawingOptionsCollectionView.isHidden = true
        textToolbar.isHidden = true
        textToolbar.isHidden = false
        currentEditMode = .addText
        currentSubMode = .none
        drawingOverlay.isUserInteractionEnabled = false
        drawingPanGesture.isEnabled = false
        clearSelection()
        clearAnnotationToolbarSelection()
    }
    
    private func hideAllToolbars() {
        mainToolbar.isHidden = true
        editToolbar.isHidden = true
        annotationToolbar.isHidden = true
        textToolbar.isHidden = true
        pageContainer.isHidden = true
        drawingOptionsCollectionView.isHidden = true
    }
    
    private func clearSelection() {
        selectionStartPoint = nil
        currentSelection = nil
        isSelecting = false
        pdfView.setCurrentSelection(nil, animate: false)
    }
    
    // MARK: - Annotation Toolbar Button Selection Helpers
    
    private func clearAnnotationToolbarSelection() {
        selectedAnnotationButton = nil
        for btn in [copyButton, underlineButton, strikethroughButton, highlightButton] {
            btn?.tintColor = navyUIKit
            if let view = btn?.value(forKey: "view") as? UIView {
                view.backgroundColor = .clear
                view.layer.cornerRadius = 0
            }
        }
        drawToggleButton.tintColor = navyUIKit
        let drawView = drawToggleButton.value(forKey: "view") as? UIView
        drawView?.backgroundColor = .clear
        drawView?.layer.cornerRadius = 0
    }
    
    private func selectAnnotationToolbarButton(_ button: UIBarButtonItem?) {
        clearAnnotationToolbarSelection()
        selectedAnnotationButton = button
        if let button = button, let view = button.value(forKey: "view") as? UIView {
            button.tintColor = .white
            view.backgroundColor = navyUIKit
            view.layer.cornerRadius = 6
            view.layer.masksToBounds = true
        }
        // If selection is nil, clear all
        if button == nil {
            // No button selected, e.g. drawing mode
            drawToggleButton.tintColor = navyUIKit
            let drawView = drawToggleButton.value(forKey: "view") as? UIView
            drawView?.backgroundColor = .clear
            drawView?.layer.cornerRadius = 0
        }
    }
    
    private func updateAnnotationToolbarSelection() {
        switch currentSubMode {
        case .copy:
            selectAnnotationToolbarButton(copyButton)
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
        case .underline:
            selectAnnotationToolbarButton(underlineButton)
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
        case .strikethrough:
            selectAnnotationToolbarButton(strikethroughButton)
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
        case .highlight:
            selectAnnotationToolbarButton(highlightButton)
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
        case .drawing:
            selectAnnotationToolbarButton(nil)
            drawingOverlay.isUserInteractionEnabled = true
            drawingPanGesture.isEnabled = true
            updateDrawingOverlayAppearance()
        default:
            clearAnnotationToolbarSelection()
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
        }
    }
    
    private func updateDrawingOverlayAppearance() {
        drawingOverlay.strokeColor = selectedColor
        drawingOverlay.strokeWidth = selectedThickness
    }
    
    // MARK: - Actions
    
    @objc private func dismissView() {
        // Save the PDF with annotations before dismissing to overwrite original file for persistence
        savePDFWithAnnotations { [weak self] savedURL in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let savedURL = savedURL {
                    do {
                        // Overwrite the original file with saved annotated PDF
                        try FileManager.default.removeItem(at: self.fileURL)
                    } catch {
                        // Ignore error if file does not exist
                    }
                    do {
                        try FileManager.default.copyItem(at: savedURL, to: self.fileURL)
                    } catch {
                        self.showAlert(title: NSLocalizedString("Error", comment: "Error alert title"), message: error.localizedDescription)
                        return
                    }
                } else {
                    self.showAlert(title: NSLocalizedString("Error", comment: "Error alert title"), message: NSLocalizedString("Could not save annotated PDF", comment: "PDF save error message"))
                    return
                }
                self.dismiss(animated: true) {
                    self.onDismiss?()
                }
            }
        }
    }
    
    @objc private func shareDocument() {
        // Save the PDF with annotations before sharing
        savePDFWithAnnotations { [weak self] savedURL in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let activityVC = UIActivityViewController(
                    activityItems: [savedURL ?? self.fileURL],
                    applicationActivities: nil
                )
                activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
                self.present(activityVC, animated: true)
            }
        }
    }
    
    @objc private func toggleViewMode() {
        isVerticalMode.toggle()
        
        if isVerticalMode {
            pdfView.displayDirection = .vertical
            pdfView.displayMode = .singlePageContinuous
        } else {
            pdfView.displayDirection = .horizontal
            pdfView.displayMode = .singlePageContinuous
        }
        
        if let items = mainToolbar.items {
            for item in items {
                if item.image == UIImage(systemName: "doc.text") || item.image == UIImage(systemName: "rectangle.grid.1x2") {
                    item.image = UIImage(systemName: isVerticalMode ? "doc.text" : "rectangle.grid.1x2")
                    break
                }
            }
        }
        
        showTempMessage(isVerticalMode ? NSLocalizedString("Vertical View", comment: "Vertical view message") : NSLocalizedString("Horizontal View", comment: "Horizontal view message"))
    }
    
    @objc private func showPageNavigation() {
        pageContainer.isHidden = !pageContainer.isHidden
        updatePageInfo()
    }
    
    @objc private func showEditMode() {
        showEditToolbar()
    }
    
    @objc private func showAnnotateMode() {
        currentSubMode = .highlight
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
        showTempMessage(NSLocalizedString("Copy Mode - Select text to copy", comment: "Copy mode message"))
        updateAnnotationToolbarSelection()
        clearSelection()
    }
    
    @objc private func enableUnderlineMode() {
        currentSubMode = .underline
        showTempMessage(NSLocalizedString("Underline Mode - Select text to underline", comment: "Underline mode message"))
        updateAnnotationToolbarSelection()
        clearSelection()
    }
    
    @objc private func enableStrikethroughMode() {
        currentSubMode = .strikethrough
        showTempMessage(NSLocalizedString("Strikethrough Mode - Select text to strikethrough", comment: "Strikethrough mode message"))
        updateAnnotationToolbarSelection()
        clearSelection()
    }
    
    @objc private func enableHighlightMode() {
        currentSubMode = .highlight
        showTempMessage(NSLocalizedString("Highlight Mode - Select text to highlight", comment: "Highlight mode message"))
        updateAnnotationToolbarSelection()
        clearSelection()
    }
    
    @objc private func toggleDrawingMode() {
        if currentSubMode == .drawing {
            currentSubMode = .highlight
            drawingOptionsCollectionView.isHidden = true
            drawingOverlay.isUserInteractionEnabled = false
            drawingPanGesture.isEnabled = false
            showTempMessage(NSLocalizedString("Exited Drawing Mode", comment: "Exit drawing mode message"))
            updateAnnotationToolbarSelection()
        } else {
            currentSubMode = .drawing
            drawingOptionsCollectionView.isHidden = false
            drawingOverlay.isUserInteractionEnabled = true
            drawingPanGesture.isEnabled = true
            updateDrawingOverlayAppearance()
            showTempMessage(NSLocalizedString("Drawing Mode - Draw on PDF", comment: "Drawing mode message"))
            updateAnnotationToolbarSelection()
        }
        clearSelection()
    }
    
    @objc private func undoAnnotation() {
        guard !undoStack.isEmpty else { return }
        
        let command = undoStack.removeLast()
        command.undo()
        redoStack.append(command)
        
        // Remove text annotation overlay if it exists
        if let textOverlay = textAnnotationOverlays[command.annotation] {
            textOverlay.removeFromSuperview()
            textAnnotationOverlays.removeValue(forKey: command.annotation)
        }
        
        // Persist PDF after undo
        persistPDF()
    }
    
    @objc private func redoAnnotation() {
        guard !redoStack.isEmpty else { return }
        
        let command = redoStack.removeLast()
        command.execute()
        undoStack.append(command)
        
        // Add text annotation overlay back if needed
        if command.annotation.type == "FreeText" && command.isAdd {
            addTextAnnotationOverlay(for: command.annotation)
        }
        
        // Persist PDF after redo
        persistPDF()
    }
    
    // MARK: - Text Mode Actions
        
    @objc private func enableTextInputMode() {
        currentSubMode = .textInput
        showTempMessage(NSLocalizedString("Tap anywhere to add text", comment: "Text input mode message"))
    }
    
    @objc private func showTextSizeOptions() {
        let alert = UIAlertController(title: NSLocalizedString("Text Size", comment: "Text size option title"), message: NSLocalizedString("Select text size", comment: "Text size option message"), preferredStyle: .actionSheet)
        
        let sizes: [CGFloat] = [8, 10, 12, 14, 16, 18, 20, 24, 28, 32]
        
        for size in sizes {
            let action = UIAlertAction(title: String(format: NSLocalizedString("%dpt", comment: "Text size option subtitle format"), Int(size)), style: .default) { _ in
                self.currentTextSize = size
                self.showTempMessage(String(format: NSLocalizedString("Text size: %dpt", comment: "Text size changed message"), Int(size)))
            }
            if size == currentTextSize {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showTextColorOptions() {
        let alert = UIAlertController(title: NSLocalizedString("Text Color", comment: "Text color option title"), message: NSLocalizedString("Select text color", comment: "Text color option message"), preferredStyle: .actionSheet)
        
        let colors: [(String, UIColor)] = [
            (NSLocalizedString("Black", comment: "Text color option name"), .label),
            (NSLocalizedString("Red", comment: "Text color option name"), .systemRed),
            (NSLocalizedString("Blue", comment: "Text color option name"), .systemBlue),
            (NSLocalizedString("Green", comment: "Text color option name"), .systemGreen),
            (NSLocalizedString("Orange", comment: "Text color option name"), .systemOrange),
            (NSLocalizedString("Purple", comment: "Text color option name"), .systemPurple),
            (NSLocalizedString("Yellow", comment: "Text color option name"), .systemYellow),
            (NSLocalizedString("Pink", comment: "Text color option name"), .systemPink)
        ]
        
        for (name, color) in colors {
            let action = UIAlertAction(title: name, style: .default) { _ in
                self.currentTextColor = color
                self.showTempMessage(String(format: NSLocalizedString("Text color: %@", comment: "Text color changed message"), name))
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Page Navigation
    
    @objc private func previousPage() {
        pdfView.goToPreviousPage(nil)
    }
    
    @objc private func nextPage() {
        pdfView.goToNextPage(nil)
    }
    
    @objc private func pageTextFieldChanged() {
        guard let text = pageTextField.text,
              let pageNumber = Int(text),
              let document = pdfDocument,
              pageNumber > 0 && pageNumber <= document.pageCount else {
            updatePageInfo()
            return
        }
        
        if let page = document.page(at: pageNumber - 1) {
            pdfView.go(to: page)
        }
    }
    
    @objc private func pdfViewPageChanged() {
        updatePageInfo()
        loadTextAnnotationOverlays()
    }
    
    private func updatePageInfo() {
        guard let document = pdfDocument else { return }
        
        let currentPage = pdfView.currentPage
        let currentPageIndex = currentPage != nil ? document.index(for: currentPage!) + 1 : 1
        let totalPages = document.pageCount
        
        pageTextField.text = "\(currentPageIndex)"
        pageLabel.text = String(format: NSLocalizedString("of %d", comment: "Page count label"), totalPages)
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: pdfView)
        
        switch currentSubMode {
        case .textInput:
            addTextAnnotation(at: point)
        case .drawing:
            break // Drawing is handled by pan gesture on drawingOverlay
        default:
            if currentEditMode == .annotate {
                selectionStartPoint = point
                isSelecting = true
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: pdfView)
        
        switch currentSubMode {
        case .copy:
            handleCopySelection(gesture)
        default:
            if currentEditMode == .annotate {
                handleTextSelection(gesture)
            }
        }
    }
    
    @objc private func handleDrawingPan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: drawingOverlay)
        
        switch gesture.state {
        case .began:
            drawingOverlay.startDrawing(at: point)
        case .changed:
            drawingOverlay.continueDrawing(to: point)
        case .ended, .cancelled:
            drawingOverlay.endDrawing()
            
            // Convert drawing to PDF annotation
            if let path = drawingOverlay.getLastPath() {
                addInkAnnotation(with: path)
            }
        default:
            break
        }
    }
    
    private func handleTextSelection(_ gesture: UIPanGestureRecognizer) {
        guard let startPoint = selectionStartPoint ?? ((gesture.state == .began) ? gesture.location(in: pdfView) : nil) else { return }
        let currentPoint = gesture.location(in: pdfView)
        switch gesture.state {
        case .began:
            selectionStartPoint = startPoint
            if let selection = createSelection(from: startPoint, to: currentPoint) {
                pdfView.setCurrentSelection(selection, animate: false)
                currentSelection = selection
            }
            isSelecting = true
        case .changed:
            if let selection = createSelection(from: startPoint, to: currentPoint) {
                pdfView.setCurrentSelection(selection, animate: false)
                currentSelection = selection
            }
        case .ended:
            if let selection = currentSelection {
                applyAnnotationToSelection(selection)
            }
            clearSelection()
            isSelecting = false
        case .cancelled:
            clearSelection()
            isSelecting = false
        default:
            break
        }
    }
    
    private func handleCopySelection(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: pdfView)
        
        switch gesture.state {
        case .began:
            selectionStartPoint = currentPoint
            if let selection = createSelection(from: currentPoint, to: currentPoint) {
                pdfView.setCurrentSelection(selection, animate: false)
                currentSelection = selection
            }
            isSelecting = true
        case .changed:
            guard let startPoint = selectionStartPoint else { return }
            if let selection = createSelection(from: startPoint, to: currentPoint) {
                pdfView.setCurrentSelection(selection, animate: false)
                currentSelection = selection
            }
        case .ended:
            guard let selection = currentSelection else {
                clearSelection()
                return
            }
            // Copy text silently with brief notification
            UIPasteboard.general.string = selection.string
            showTempMessage(NSLocalizedString("Text copied", comment: "Copy confirmation message"))
            clearSelection()
            isSelecting = false
        case .cancelled:
            clearSelection()
            isSelecting = false
        default:
            break
        }
    }

    private func createSelection(from startPoint: CGPoint, to endPoint: CGPoint) -> PDFSelection? {
        guard let startPage = pdfView.page(for: startPoint, nearest: true),
              let endPage = pdfView.page(for: endPoint, nearest: true) else {
            return nil
        }
        
        let startPagePoint = pdfView.convert(startPoint, to: startPage)
        let endPagePoint = pdfView.convert(endPoint, to: endPage)
        
        // If selection is on the same page
        if startPage == endPage {
            return startPage.selection(from: startPagePoint, to: endPagePoint)
        } else {
            // Handle multi-page selection
            guard let document = pdfDocument else { return nil }
            
            let startPageIndex = document.index(for: startPage)
            let endPageIndex = document.index(for: endPage)
            
            var selections: [PDFSelection] = []
            
            // Add selection from start point to end of start page
            let startPageEndPoint = CGPoint(x: startPage.bounds(for: .mediaBox).maxX,
                                          y: startPage.bounds(for: .mediaBox).maxY)
            if let startSelection = startPage.selection(from: startPagePoint, to: startPageEndPoint) {
                selections.append(startSelection)
            }
            
            // Add full page selections for intermediate pages
            for i in (min(startPageIndex, endPageIndex) + 1)..<max(startPageIndex, endPageIndex) {
                if let page = document.page(at: i) {
                    let pageRect = page.bounds(for: .mediaBox)
                    if let pageSelection = page.selection(for: pageRect) {
                        selections.append(pageSelection)
                    }
                }
            }
            
            // Add selection from start of end page to end point
            let endPageStartPoint = CGPoint(x: endPage.bounds(for: .mediaBox).minX,
                                          y: endPage.bounds(for: .mediaBox).minY)
            if let endSelection = endPage.selection(from: endPageStartPoint, to: endPagePoint) {
                selections.append(endSelection)
            }
            
            // Combine all selections
            var combinedSelection: PDFSelection?
            for selection in selections {
                if combinedSelection == nil {
                    combinedSelection = selection
                } else {
                    combinedSelection?.add(selection)
                }
            }
            
            return combinedSelection
        }
    }
        
    // MARK: - Annotation Creation
    
    private func addTextAnnotation(at point: CGPoint) {
        guard let page = pdfView.page(for: point, nearest: true) else { return }
        
        // Custom alert controller with real-time preview label
        let alert = UIAlertController(title: NSLocalizedString("Add Text", comment: "Add text alert title"), message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = NSLocalizedString("Enter text", comment: "Add text alert placeholder")
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.addTarget(self, action: #selector(self.textFieldDidChangeInAlert(_:)), for: .editingChanged)
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Add", comment: "Add button title"), style: .default) { _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            
            let pagePoint = self.pdfView.convert(point, to: page)
            let bounds = CGRect(x: pagePoint.x, y: pagePoint.y - 10, width: 100, height: 20)
            
            let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
            annotation.contents = text
            annotation.font = UIFont.systemFont(ofSize: self.currentTextSize)
            annotation.fontColor = self.currentTextColor
            annotation.backgroundColor = UIColor.clear
            
            page.addAnnotation(annotation)
            
            // Add to undo stack
            let command = AnnotationCommand(annotation: annotation, page: page, isAdd: true)
            self.undoStack.append(command)
            self.redoStack.removeAll()
            
            // Add overlay for movable text
            self.addTextAnnotationOverlay(for: annotation)
            
            // Persist PDF immediately
            self.persistPDF()
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .cancel))
        
        // Present alert and add preview label after presentation to avoid crash
        self.present(alert, animated: true) {
            // Add a container view for preview label below text field (using KVC to access alert's view)
            let margin: CGFloat = 8.0
            let previewLabel = UILabel(frame: CGRect(x: margin, y: 65, width: 250, height: 40))
            previewLabel.numberOfLines = 2
            previewLabel.textAlignment = .center
            previewLabel.font = UIFont.systemFont(ofSize: self.currentTextSize)
            previewLabel.textColor = self.currentTextColor
            previewLabel.layer.cornerRadius = 6
            previewLabel.layer.masksToBounds = true
            previewLabel.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.5)
            previewLabel.text = ""
            
            alert.view.addSubview(previewLabel)
            
            // Constraint for preview label
            previewLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                previewLabel.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: margin * 1.5),
                previewLabel.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -margin * 1.5),
                previewLabel.topAnchor.constraint(equalTo: alert.textFields!.first!.bottomAnchor, constant: 8),
                previewLabel.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            // Store preview label reference for text field change selector
            objc_setAssociatedObject(alert, &AssociatedKeys.previewLabelKey, previewLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(alert, &AssociatedKeys.textSizeKey, self.currentTextSize, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(alert, &AssociatedKeys.textColorKey, self.currentTextColor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // Associated keys for objc_setAssociatedObject
    private struct AssociatedKeys {
        static var previewLabelKey = "previewLabelKey"
        static var textSizeKey = "textSizeKey"
        static var textColorKey = "textColorKey"
    }
    
    @objc private func textFieldDidChangeInAlert(_ textField: UITextField) {
        guard let alert = self.presentedViewController as? UIAlertController,
              let previewLabel = objc_getAssociatedObject(alert, &AssociatedKeys.previewLabelKey) as? UILabel else { return }
        
        previewLabel.text = textField.text
        previewLabel.font = UIFont.systemFont(ofSize: currentTextSize)
        previewLabel.textColor = currentTextColor
    }
    
    private func addInkAnnotation(with path: UIBezierPath) {
        guard let currentPage = pdfView.currentPage else { return }
        
        // The path points are in drawingOverlay coordinates
        // Convert each point to pdfView, then to currentPage coordinates
        var pdfPoints: [CGPoint] = []
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                let ptInOverlay = element.pointee.points[0]
                let ptInPDFView = drawingOverlay.convert(ptInOverlay, to: pdfView)
                let ptInPage = pdfView.convert(ptInPDFView, to: currentPage)
                pdfPoints.append(ptInPage)
            default:
                break
            }
        }
        
        guard !pdfPoints.isEmpty else { return }
        
        // Create new UIBezierPath in PDF page coordinates
        let inkPath = UIBezierPath()
        inkPath.move(to: pdfPoints[0])
        for pt in pdfPoints.dropFirst() {
            inkPath.addLine(to: pt)
        }
        
        // Calculate bounds for annotation
        let bounds = inkPath.bounds.insetBy(dx: -selectedThickness, dy: -selectedThickness)
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = selectedColor
        
        annotation.add(inkPath)
        let border = PDFBorder()
        border.lineWidth = selectedThickness
        annotation.border = border
        currentPage.addAnnotation(annotation)
        
        // Add to undo stack
        let command = AnnotationCommand(annotation: annotation, page: currentPage, isAdd: true)
        undoStack.append(command)
        redoStack.removeAll()
        
        // Force PDFView to redraw to reflect new annotation immediately
        pdfView.setNeedsDisplay()
        pdfView.layoutIfNeeded()
        
        // Persist PDF immediately
        persistPDF()
    }
    
    private func applyAnnotationToSelection(_ selection: PDFSelection) {
        guard let page = selection.pages.first else { return }
        
        let bounds = selection.bounds(for: page)
        
        var annotation: PDFAnnotation?
        
        switch currentSubMode {
        case .highlight:
            annotation = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
            annotation?.color = .systemYellow
        case .underline:
            annotation = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
            annotation?.color = navyUIKit
        case .strikethrough:
            // Use native strikeOut annotation type with proper color
            annotation = PDFAnnotation(bounds: bounds, forType: .strikeOut, withProperties: nil)
            annotation?.color = .systemRed
        case .copy:
            UIPasteboard.general.string = selection.string
            // Brief notification only
            showTempMessage(NSLocalizedString("Text copied", comment: "Copy confirmation message"))
            return
        default:
            return
        }
        
        if let annotation = annotation {
            page.addAnnotation(annotation)
            
            // Add to undo stack
            let command = AnnotationCommand(annotation: annotation, page: page, isAdd: true)
            undoStack.append(command)
            redoStack.removeAll()
            
            // Persist PDF immediately
            persistPDF()
        }
    }
    
    // MARK: - Text Annotation Overlays
    
    private func addTextAnnotationOverlay(for annotation: PDFAnnotation) {
        guard annotation.type == "FreeText" else { return }
        
        let overlay = TextAnnotationOverlayView(annotation: annotation, pdfView: pdfView)
        pdfView.addSubview(overlay)
        textAnnotationOverlays[annotation] = overlay
    }
    
    @objc private func loadTextAnnotationOverlays() {
        // Clear existing overlays
        textAnnotationOverlays.values.forEach { $0.removeFromSuperview() }
        textAnnotationOverlays.removeAll()
        
        // Add overlays for text annotations on current page
        guard let currentPage = pdfView.currentPage else { return }
        
        for annotation in currentPage.annotations {
            if annotation.type == "FreeText" {
                addTextAnnotationOverlay(for: annotation)
            }
        }
    }
    
    @objc private func handleTextAnnotationOverlayDeleted(_ notification: Notification) {
        guard let annotation = notification.object as? PDFAnnotation else { return }
        
        // Remove from tracking
        textAnnotationOverlays.removeValue(forKey: annotation)
        
        // Add to undo stack
        if let page = annotation.page {
            let command = AnnotationCommand(annotation: annotation, page: page, isAdd: false)
            undoStack.append(command)
            redoStack.removeAll()
        }
        
        // Persist PDF after deletion
        persistPDF()
    }
    
    // MARK: - PDF Saving
    
    private func savePDFWithAnnotations(completion: @escaping (URL?) -> Void) {
        guard let document = pdfDocument else {
            completion(nil)
            return
        }
        
        // Create a temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("annotated_\(UUID().uuidString).pdf")
        
        // Save the document with annotations
        DispatchQueue.global(qos: .userInitiated).async {
            let success = document.write(to: tempURL)
            completion(success ? tempURL : nil)
        }
    }
    
    private func persistPDF() {
        // Save the PDF with annotations and overwrite original file for persistence
        savePDFWithAnnotations { [weak self] savedURL in
            guard let self = self else { return }
            guard let savedURL = savedURL else { return }
            
            do {
                if FileManager.default.fileExists(atPath: self.fileURL.path) {
                    try FileManager.default.removeItem(at: self.fileURL)
                }
                try FileManager.default.copyItem(at: savedURL, to: self.fileURL)
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: NSLocalizedString("Error", comment: "Error alert title"), message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func showTempMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button title"), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate for Drawing Options

extension EnhancedPDFViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Section 0 = colors, Section 1 = thicknesses
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return drawingColors.count
        } else {
            return drawingThicknesses.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DrawingOptionCell.reuseIdentifier, for: indexPath) as? DrawingOptionCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.section == 0 {
            let color = drawingColors[indexPath.item]
            cell.configureAsColor(color: color, selected: color.isEqual(selectedColor))
        } else {
            let thickness = drawingThicknesses[indexPath.item]
            cell.configureAsThickness(thickness: thickness, selected: thickness == selectedThickness)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let color = drawingColors[indexPath.item]
            selectedColor = color
        } else {
            let thickness = drawingThicknesses[indexPath.item]
            selectedThickness = thickness
        }
        updateDrawingOverlayAppearance()
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewCell for Drawing Options

private class DrawingOptionCell: UICollectionViewCell {
    static let reuseIdentifier = "DrawingOptionCell"
    
    private let colorView = UIView()
    private let thicknessView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
        contentView.addSubview(thicknessView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        thicknessView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 30),
            colorView.heightAnchor.constraint(equalToConstant: 30),
            
            thicknessView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thicknessView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thicknessView.widthAnchor.constraint(equalToConstant: 30),
            thicknessView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        colorView.layer.cornerRadius = 15
        colorView.layer.borderWidth = 1
        colorView.layer.borderColor = UIColor.gray.cgColor
        thicknessView.layer.cornerRadius = 15
        thicknessView.layer.borderWidth = 1
        thicknessView.layer.borderColor = UIColor.gray.cgColor
        thicknessView.backgroundColor = .clear
        
        self.layer.cornerRadius = 18
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureAsColor(color: UIColor, selected: Bool) {
        colorView.isHidden = false
        thicknessView.isHidden = true
        
        colorView.backgroundColor = color
        layer.borderWidth = selected ? 3 : 0
        layer.borderColor = selected ? navyUIKit.cgColor : nil
    }
    
    func configureAsThickness(thickness: CGFloat, selected: Bool) {
        colorView.isHidden = true
        thicknessView.isHidden = false
        
        // Circle sized by thickness, centered inside thicknessView
        thicknessView.subviews.forEach { $0.removeFromSuperview() }
        let circle = UIView()
        circle.backgroundColor = .label
        circle.layer.cornerRadius = thickness / 2
        circle.translatesAutoresizingMaskIntoConstraints = false
        thicknessView.addSubview(circle)
        
        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: thicknessView.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: thicknessView.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: thickness),
            circle.heightAnchor.constraint(equalToConstant: thickness)
        ])
        
        layer.borderWidth = selected ? 3 : 0
        layer.borderColor = selected ? navyUIKit.cgColor : nil
    }
}

// MARK: - Extensions

extension EnhancedPDFViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            searchResults.removeAll()
            currentSearchIndex = 0
            return
        }
        
        guard let document = pdfDocument else { return }
        
        searchResults.removeAll()
        
        // Using document.findString once is enough, no need to loop pages unnecessarily
        let selections = document.findString(searchText, withOptions: .caseInsensitive)
        searchResults.append(contentsOf: selections)
        
        if !searchResults.isEmpty {
            currentSearchIndex = 0
            highlightSearchResult()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if !searchResults.isEmpty {
            currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
            highlightSearchResult()
        }
    }
    
    private func highlightSearchResult() {
        guard currentSearchIndex < searchResults.count else { return }
        
        let selection = searchResults[currentSearchIndex]
        pdfView.setCurrentSelection(selection, animate: true)
        pdfView.go(to: selection)
    }
}

extension EnhancedPDFViewController: PDFViewDelegate {
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        // Handle link clicks if needed
        UIApplication.shared.open(url)
    }
}

extension EnhancedPDFViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension EnhancedPDFViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}


//
//  TextAnnotationOverlayView.swift
//  Hanuman PDF Readers
//
//  Created by Neeshu Kumar on 16/06/25.
//

import UIKit
import PDFKit
import SwiftUI

// MARK: - Text Annotation Overlay View
class TextAnnotationOverlayView: UIView {
    private let annotation: PDFAnnotation
    private weak var pdfView: PDFView?
    private var deleteButton: UIButton!
    private var resizeHandle: UIView!
    
    init(annotation: PDFAnnotation, pdfView: PDFView) {
        self.annotation = annotation
        self.pdfView = pdfView
        super.init(frame: .zero)
        setupUI()
        updateFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        
        // Delete button
        deleteButton = UIButton(type: .system)
        deleteButton.setTitle("×", for: .normal)
        deleteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        deleteButton.backgroundColor = UIColor.systemRed
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.layer.cornerRadius = 10
        deleteButton.addTarget(self, action: #selector(deleteAnnotation), for: .touchUpInside)
        addSubview(deleteButton)
        
        // Resize handle
        resizeHandle = UIView()
        resizeHandle.backgroundColor = UIColor.systemBlue
        resizeHandle.layer.cornerRadius = 4
        addSubview(resizeHandle)
        
        // Add pan gesture for moving
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // Add tap gesture for editing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(editText))
        addGestureRecognizer(tapGesture)
    }
    
    private func updateFrame() {
        guard let pdfView = pdfView, let page = annotation.page else { return }
        
        let bounds = annotation.bounds
        let viewBounds = pdfView.convert(bounds, from: page)
        frame = viewBounds.insetBy(dx: -5, dy: -5)
        
        // Position delete button
        deleteButton.frame = CGRect(x: frame.width - 25, y: -5, width: 20, height: 20)
        
        // Position resize handle
        resizeHandle.frame = CGRect(x: frame.width - 8, y: frame.height - 8, width: 8, height: 8)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let pdfView = pdfView, let page = annotation.page else { return }
        
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .changed:
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
            
            // Update annotation bounds
            let newViewBounds = frame.insetBy(dx: 5, dy: 5)
            let newPDFBounds = pdfView.convert(newViewBounds, to: page)
            annotation.bounds = newPDFBounds
            
        default:
            break
        }
    }
    
    @objc private func editText() {
        let alert = UIAlertController(title: "Edit Text", message: "Update the text", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = self.annotation.contents
            textField.placeholder = "Enter text"
        }
        
        alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.annotation.contents = text
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let viewController = pdfView?.parentViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    @objc private func deleteAnnotation() {
        annotation.page?.removeAnnotation(annotation)
        NotificationCenter.default.post(name: .textAnnotationOverlayDidDelete, object: annotation)
        removeFromSuperview()
    }
}

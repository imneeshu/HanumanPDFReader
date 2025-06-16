//
//  DirectPDFView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI

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

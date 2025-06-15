//
//  ShareSheet.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//


import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {}
}

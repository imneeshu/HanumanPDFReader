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


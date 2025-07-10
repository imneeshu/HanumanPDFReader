//
//  CameraOCRView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 09/06/25.
//

import SwiftUI
import VisionKit

import SwiftUI
import WeScan
import UIKit

struct CameraOCRView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingViewModel : SettingsViewModel
    @Binding var capturedImages: [UIImage]
    var isAutoCapture: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> ImageScannerController {
        let scannerVC = ImageScannerController()
        scannerVC.imageScannerDelegate = context.coordinator
        if settingViewModel.isDarkMode{
            scannerVC.view.backgroundColor = navyUIKit
        }
        else{
            scannerVC.view.backgroundColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0) // Light-medium blue

        }
        return scannerVC
    }

    func updateUIViewController(_ uiViewController: ImageScannerController, context: Context) {
        // No update needed
    }

    class Coordinator: NSObject, ImageScannerControllerDelegate {
        let parent: CameraOCRView

        init(_ parent: CameraOCRView) {
            self.parent = parent
        }

        func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
            parent.capturedImages.append(results.originalScan.image)
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
            print("WeScan error: \(error)")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

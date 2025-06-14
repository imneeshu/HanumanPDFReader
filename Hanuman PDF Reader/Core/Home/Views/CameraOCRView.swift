//
//  CameraOCRView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 09/06/25.
//

import SwiftUI
import VisionKit

//struct CameraOCRView: UIViewControllerRepresentable {
//    @Environment(\.presentationMode) var presentationMode
//    @Binding var capturedImages: [UIImage]
//    var isAutoCapture: Bool
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
//        let scannerVC = VNDocumentCameraViewController()
//        scannerVC.delegate = context.coordinator
//        return scannerVC
//    }
//
//    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
//        // No-op
//    }
//
//    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
//        let parent: CameraOCRView
//
//        init(_ parent: CameraOCRView) {
//            self.parent = parent
//        }
//
//        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
//            for i in 0..<scan.pageCount {
//                let image = scan.imageOfPage(at: i)
//                parent.capturedImages.append(image)
//            }
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//
//        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//
//        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
//            print("Scanner error: \(error.localizedDescription)")
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//    }
//}


import SwiftUI
import WeScan
import UIKit

struct CameraOCRView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var capturedImages: [UIImage]
    var isAutoCapture: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> ImageScannerController {
        let scannerVC = ImageScannerController()
        scannerVC.imageScannerDelegate = context.coordinator
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

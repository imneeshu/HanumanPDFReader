//
//  PDFCreator.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 09/06/25.
//

import Foundation
import UIKit

class PDFCreator {
    let images: [UIImage]
    let name: String

    init(images: [UIImage], name: String) {
        self.images = images
        self.name = name
    }

    func createPDF() -> URL? {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

        for image in images {
            let pageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            image.draw(in: pageRect)
        }

        UIGraphicsEndPDFContext()

        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("\(name).pdf")
        pdfData.write(to: pdfURL, atomically: true)

        return pdfURL
    }
}

//
//  DrawingOverlayView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import UIKit
import PDFKit
import SwiftUI

// MARK: - Drawing Overlay View
class DrawingOverlayView: UIView {
    struct Stroke {
        let path: UIBezierPath
        let color: UIColor
        let width: CGFloat
    }
    
    var currentPath: UIBezierPath?
    var currentColor: UIColor = .systemRed
    var currentWidth: CGFloat = 2.0
    var strokes: [Stroke] = []
    var strokeColor: UIColor = .systemRed {
        didSet { currentColor = strokeColor }
    }
    var strokeWidth: CGFloat = 2.0 {
        didSet { currentWidth = strokeWidth }
    }

    override func draw(_ rect: CGRect) {
        // Draw all completed strokes
        for stroke in strokes {
            stroke.color.setStroke()
            stroke.path.lineWidth = stroke.width
            stroke.path.stroke()
        }
        // Draw current path
        if let currentPath = currentPath {
            currentColor.setStroke()
            currentPath.lineWidth = currentWidth
            currentPath.stroke()
        }
    }
    
    func startDrawing(at point: CGPoint) {
        print("[DrawingOverlayView] startDrawing at \(point)")
        currentPath = UIBezierPath()
        currentPath?.move(to: point)
        currentPath?.lineCapStyle = .round
        currentPath?.lineJoinStyle = .round
        setNeedsDisplay()
    }
    
    func continueDrawing(to point: CGPoint) {
        print("[DrawingOverlayView] continueDrawing to \(point)")
        currentPath?.addLine(to: point)
        setNeedsDisplay()
    }
    
    func endDrawing() {
        print("[DrawingOverlayView] endDrawing")
        guard let path = currentPath else { return }
        let stroke = Stroke(path: path, color: currentColor, width: currentWidth)
        strokes.append(stroke)
        currentPath = nil
        setNeedsDisplay()
    }
    
    func getLastPath() -> UIBezierPath? {
        return strokes.last?.path
    }
    
    func removeLastPath() {
        if !strokes.isEmpty {
            strokes.removeLast()
            setNeedsDisplay()
        }
    }
    
    func clearAllPaths() {
        strokes.removeAll()
        currentPath = nil
        setNeedsDisplay()
    }
    
    func setStrokeColor(_ color: UIColor) {
        strokeColor = color
    }
}



extension Notification.Name {
    static let textAnnotationOverlayDidDelete = Notification.Name("textAnnotationOverlayDidDelete")
}

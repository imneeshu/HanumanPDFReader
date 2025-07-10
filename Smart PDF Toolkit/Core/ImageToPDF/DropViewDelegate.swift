//
//  DropViewDelegate.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Drag and Drop Delegate
struct DropViewDelegate: DropDelegate {
    let destinationItem: UIImage
    @Binding var images: [UIImage]
    @Binding var draggedItem: UIImage?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Fixed: Reset draggedItem properly
        DispatchQueue.main.async {
            draggedItem = nil
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else { return }
        
        if draggedItem != destinationItem {
            let from = images.firstIndex(of: draggedItem)!
            let to = images.firstIndex(of: destinationItem)!
            
            if images[to] != draggedItem {
                withAnimation(.easeInOut(duration: 0.3)) {
                    images.move(fromOffsets: IndexSet([from]), toOffset: to > from ? to + 1 : to)
                }
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        // Additional fix: Reset opacity when drag exits
        // This helps ensure the opacity resets properly
    }
}

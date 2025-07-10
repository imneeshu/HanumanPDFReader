//
//  ReorderableFileRow.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers


// MARK: - Reorderable File Row
struct ReorderableFileRow: View {
    let file: FileItem
    
    var body: some View {
        HStack(spacing: 12) {
//            // Drag Handle
//            Image(systemName: "line.3.horizontal")
//                .foregroundColor(.gray)
//                .font(.system(size: 18))
//                .frame(width: 24)
            
            // File icon
            fileTypeIcon
                .frame(width: 44, height: 44)
                .overlay(
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            .black,
//                            Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
//                            Color(red: 0.6, green: 0.4, blue: 0.9),
//                            Color(red: 0.8, green: 0.3, blue: 0.8)
//                        ]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
                    navy
                    .mask(fileTypeIcon)
                )
                .background(fileTypeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // File info
            VStack(alignment: .leading, spacing: 6) {
                Text(file.name ?? "Unknown")
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(file.fileTypeEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(fileTypeColor.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if let modifiedDate = file.modifiedDate {
                        Text(formatDate(modifiedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - File Type Icon
    private var fileTypeIcon: some View {
        Image(systemName: file.fileTypeEnum.iconName)
            .font(.title2)
            .foregroundColor(fileTypeColor)
    }
    
    private var fileTypeColor: Color {
        switch file.fileTypeEnum {
        case .pdf: return navy
        case .word: return .blue
        case .excel: return .green
        case .powerpoint: return .orange
        }
    }
}

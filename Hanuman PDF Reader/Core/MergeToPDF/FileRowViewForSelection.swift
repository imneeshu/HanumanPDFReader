//
//  FileRowViewForSelection.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Original File Row (for selection)
struct FileRowViewForSelection: View {
    var file: FileItem
    var isSelected: Bool
    var onSelectionToggle: () -> Void
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingRenameAlert = false
    @State private var showingDeleteAlert = false
    @State private var newFileName = ""
    @State var previewError: String?
    @State private var showingPreview = false
    @State private var fileURLForPreview: URL?
    @Binding var listFlow : ListFlow

    var body: some View {
        VStack {
            contentRow
        }
    }

    // MARK: - File Row Content
    private var contentRow: some View {
        HStack(spacing: 12) {
            // File icon and info
            fileTypeIcon
                .frame(width: 40, height: 40)
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
                    .mask(fileTypeIcon) // mask the gradient to the icon shape
                )
                .background(fileTypeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(file.name ?? "Unknown")
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Text(file.fileTypeEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
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
            
            if listFlow == .merge{
                // Selection Checkbox
                selectionCheckbox
                    .frame(width: 24, height: 24)
                    .padding()
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionToggle()
        }
    }

    // MARK: - Selection Checkbox
    private var selectionCheckbox: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ?
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                .black,
//                                Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
//                                Color(red: 0.6, green: 0.4, blue: 0.9),
//                                Color(red: 0.8, green: 0.3, blue: 0.8)
//                            ]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
                          navy : Color.clear
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.clear]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
                    )
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1 : 0)
            )
    }

    // MARK: - Icons and Styling
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

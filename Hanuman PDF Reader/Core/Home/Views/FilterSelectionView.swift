//
//  FilterSelectionView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

// MARK: - Filter Selection View
struct FilterSelectionView: View {
    @Binding var selectedFileType: FileType?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                // All Files Option
                HStack {
                    Text("All Files")
                    Spacer()
                    if selectedFileType == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedFileType = nil
                    presentationMode.wrappedValue.dismiss()
                }
                
                // Individual File Types
                ForEach(FileType.allCases, id: \.self) { fileType in
                    HStack {
                        Image(systemName: fileType.iconName)
                            .foregroundColor(fileType.color)
                        Text(fileType.displayName)
                        Spacer()
                        if selectedFileType == fileType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFileType = fileType
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Filter By Type")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

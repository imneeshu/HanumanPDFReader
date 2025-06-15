//
//  RenameFileSheet.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

struct RenameFileSheet: View {
    @Binding var fileName: String
    let onSave: () -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Name your PDF file")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top)
                
                TextField("Enter file name", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Save PDF")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create PDF") {
                    onSave()
                }
                .fontWeight(.semibold)
                .disabled(fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

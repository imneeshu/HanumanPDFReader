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
                Text("Name_your_PDF_file")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top)
                
                TextField("Enter_file_name", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Save_PDF")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel_") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create_PDF") {
                    onSave()
                }
                .fontWeight(.semibold)
                .disabled(fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

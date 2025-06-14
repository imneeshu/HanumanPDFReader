//
//  DirectorySelectionHeader.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//


import SwiftUI

struct DirectorySelectionHeader: View {
    @State private var selectedDirectory: URL?
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Directory")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(selectedDirectory?.lastPathComponent ?? "No directory selected")
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                showingDirectoryPicker = true
            }) {
                Image(systemName: "folder")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
//                saveInCoreData(fileURLs: urls)
                if let url = urls.first {
                    //                    selectedDirectory = url
                    
                }
            case .failure(let error):
                print("Directory selection failed: \(error)")
            }
        }
    }
}

//
//  SaveShareView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI

struct SaveShareSheetContent: View {
    let pdfURL: URL
    let fileName: String
    let onViewPDF: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            SaveShareView(
                pdfURL: pdfURL,
                fileName: fileName,
                onViewPDF: onViewPDF
            )
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}

struct SaveShareView: View {
    let pdfURL: URL
    let fileName: String
    let onViewPDF: () -> Void
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("PDF Created Successfully!")
                .font(.title2)
                .fontWeight(.medium)
            
            VStack(spacing: 15) {
                // View PDF button
                Button(action: onViewPDF) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View PDF")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                           gradient: Gradient(colors: [
                               .black,
                               Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
                               Color(red: 0.6, green: 0.4, blue: 0.9),
                               Color(red: 0.8, green: 0.3, blue: 0.8)
                           ]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                }
                
                // Share button
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share PDF")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.35))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [pdfURL])
//            EmptyView()
        }
    }
}

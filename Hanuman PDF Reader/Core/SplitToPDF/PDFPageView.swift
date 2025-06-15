//
//  PDFPageView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct PDFPageView: View {
    let page: PDFPage?
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Added padding(10) inside the outermost ZStack
            Color.clear.padding(10)
            
            ZStack {
                if let page = page {
                    PDFPageThumbnailView(page: page)
                        .aspectRatio(3/4, contentMode: .fit)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "doc.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.4))
                        )
                }
            }
            .frame(maxWidth: 300)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.07), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: isSelected ? [Color.purple, Color(red: 0.8, green: 0.3, blue: 0.8)] : [Color.clear, Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 3 : 0
                    )
            )
            .overlay(
                // Purple overlay when selected
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(isSelected ? 0.11 : 0))
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .onTapGesture {
                onTap()
            }

            // Page number pill
            Text("\(pageNumber)")
                .font(.caption.weight(.bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.85))
                )
                .padding([.bottom, .trailing], 14)
        }
    }
}

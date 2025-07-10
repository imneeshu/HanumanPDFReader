//
//  EmptyStateView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.gray)
                .overlay(
                    navy
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
                    .mask(
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                    )
                )
            
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .overlay(
                    navy
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
                    .mask(
                        Text(title)
                            .font(.title2)
                            .fontWeight(.medium)
                    )
                )
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .overlay(
                    navy
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
                    .mask(
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

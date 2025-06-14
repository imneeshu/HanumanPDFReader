//
//  FeatureCard.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 11/06/25.
//

import SwiftUI

struct FeatureCard<Icon: View>: View {
    let title: String
    let subtitle: String?
    let backgroundColor: Color
    var isSmall: Bool = false
    let icon: () -> Icon
    
    var body: some View {
        Button(action: {
            // Handle tap
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .frame(height: isSmall ? 80 : 170)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(isSmall ? .system(size: 16, weight: .semibold) : .system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        icon()
                    }
                    
                    if !isSmall {
                        Spacer()
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Cloud Folder Icon
struct CloudFolderIcon: View {
    var body: some View {
        ZStack {
            // Back folder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.8))
                .frame(width: 45, height: 35)
                .offset(x: -5, y: 5)
            
            // Front folder with cloud
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .frame(width: 45, height: 35)
                
                // Cloud icon
                Image(systemName: "cloud.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
        }
        .frame(width: 50, height: 40)
    }
}


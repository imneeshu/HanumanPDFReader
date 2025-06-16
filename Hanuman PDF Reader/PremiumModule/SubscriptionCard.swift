//
//  SubscriptionCard.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI

struct SubscriptionCard: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let badge = product.badge {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(product.badgeColor)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(product.price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isPurchased ? Color.green : (isSelected ? Color.blue : Color.clear), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .disabled(isPurchased)
        .opacity(isPurchased ? 0.7 : 1.0)
    }
}

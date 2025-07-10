//
//  SubscriptionProduct.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//


import SwiftUI
import StoreKit

// MARK: - Models
struct SubscriptionProduct: Equatable {
    let id: String
    let displayName: String
    let description: String
    let price: String
    let product: Product?
    let badge: String?
    let badgeColor: Color
    let isPopular: Bool

    static func == (lhs: SubscriptionProduct, rhs: SubscriptionProduct) -> Bool {
        lhs.id == rhs.id
    }
}

enum PurchaseError: Error, LocalizedError {
    case failedVerification
    case system(Error)
    case cancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed"
        case .system(let error):
            return error.localizedDescription
        case .cancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}


// Preview
struct PremiumSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumSubscriptionView()
            .preferredColorScheme(.light)
        
        PremiumSubscriptionView()
            .preferredColorScheme(.dark)
    }
}


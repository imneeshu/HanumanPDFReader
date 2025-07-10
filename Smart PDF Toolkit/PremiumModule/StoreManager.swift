//
//  StoreManager.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI
import StoreKit

// MARK: - Store Manager (StoreKit 2)
@MainActor
class StoreManager: ObservableObject {
    @Published var products: [SubscriptionProduct] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productIds: [String] = [
        "com.hanumanpdf.premiums.monthly",
        "com.hanumanpdf.premiums.yearly",
        "com.hanumanpdf.premium.onetime"
    ]

    
    private var updates: Task<Void, Never>? = nil
    
    init() {
        updates = observeTransactionUpdates()
    }
    
    deinit {
        updates?.cancel()
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            
            var subscriptionProducts: [SubscriptionProduct] = []
            
            for product in storeProducts {
                let subscriptionProduct = SubscriptionProduct(
                    id: product.id,
                    displayName: displayName(for: product.id),
                    description: product.description,
                    price: product.displayPrice,
                    product: product,
                    badge: badge(for: product.id),
                    badgeColor: badgeColor(for: product.id),
                    isPopular: product.id.contains("yearly")
                )
                subscriptionProducts.append(subscriptionProduct)
            }
            
            // Sort products: lifetime, yearly, monthly
            self.products = subscriptionProducts.sorted { first, second in
                let order = ["lifetime": 0, "yearly": 1, "monthly": 2]
                let firstOrder = order.first { first.id.contains($0.key) }?.value ?? 3
                let secondOrder = order.first { second.id.contains($0.key) }?.value ?? 3
                return firstOrder < secondOrder
            }
            
            await updatePurchasedProducts()
            
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func purchase(_ product: SubscriptionProduct) async throws {
        guard let storeProduct = product.product else {
            throw PurchaseError.unknown
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await storeProduct.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                
            case .userCancelled:
                throw PurchaseError.cancelled
                
            case .pending:
                throw PurchaseError.pending
                
            @unknown default:
                throw PurchaseError.unknown
            }
        } catch {
            throw PurchaseError.system(error)
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProducts.insert(transaction.productID)
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
        savePremiumStatusToUserDefaults()
    }
    
    /// Saves the current premium subscription status to UserDefaults.
    ///
    /// Updates the keys "monthlySubscribed", "yearlySubscribed", and "oneTimePurchase" based on the
    /// presence of the corresponding product IDs in `purchasedProductIDs`.
    private func savePremiumStatusToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(purchasedProductIDs.contains("com.hanumanpdf.premium.monthly"), forKey: "monthlySubscribed")
        defaults.set(purchasedProductIDs.contains("com.hanumanpdf.premium.yearly"), forKey: "yearlySubscribed")
        defaults.set(purchasedProductIDs.contains("com.hanumanpdf.premium.lifetime"), forKey: "oneTimePurchase")
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    await updatePurchasedProducts()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func displayName(for productId: String) -> String {
        if productId.contains("monthly") { return "Monthly" }
        if productId.contains("yearly") { return "Yearly" }
        if productId.contains("lifetime") { return "Lifetime" }
        return "Premium"
    }
    
    private func badge(for productId: String) -> String? {
        if productId.contains("lifetime") { return "BEST VALUE" }
        if productId.contains("yearly") { return "POPULAR" }
        return nil
    }
    
    private func badgeColor(for productId: String) -> Color {
        if productId.contains("lifetime") { return .green }
        if productId.contains("yearly") { return .orange }
        return .clear
    }
    
    func isPurchased(_ productId: String) -> Bool {
        return purchasedProductIDs.contains(productId)
    }
    
    var hasAnyPremium: Bool {
        return !purchasedProductIDs.isEmpty
    }
}


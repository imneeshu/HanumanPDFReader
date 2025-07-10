//
//  PremiumViewModel.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI

// MARK: - ViewModel
@MainActor
class PremiumViewModel: ObservableObject {
    @Published var selectedProduct: SubscriptionProduct?
    @Published var showingPurchaseAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showingErrorAlert = false
    
    private let storeManager: StoreManager
    
    init(storeManager: StoreManager) {
        self.storeManager = storeManager
    }
    
    var products: [SubscriptionProduct] {
        storeManager.products
    }
    
    var isLoading: Bool {
        storeManager.isLoading
    }
    
    var hasAnyPremium: Bool {
        storeManager.hasAnyPremium
    }
    
    func loadProducts() async {
        await storeManager.loadProducts()
        
        // Automatically select the monthly plan by default if available
        if selectedProduct == nil, let monthly = storeManager.products.first(where: { $0.id.lowercased().contains("monthly") }) {
            selectedProduct = monthly
        }
        
        if let error = storeManager.errorMessage {
            showError(error)
        }
    }
    
    func selectProduct(_ product: SubscriptionProduct) {
        selectedProduct = product
    }
    
    func purchaseSelectedProduct() async {
        guard let product = selectedProduct else { return }
        
        do {
            try await storeManager.purchase(product)
            showSuccess("Purchase successful! You now have premium access.")
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func restorePurchases() async {
        await storeManager.restorePurchases()
        
        if let error = storeManager.errorMessage {
            showError(error)
        } else if storeManager.hasAnyPremium {
            showSuccess("Purchases restored successfully!")
        } else {
            showError("No previous purchases found.")
        }
    }
    
    func isPurchased(_ productId: String) -> Bool {
        storeManager.isPurchased(productId)
    }
    
    private func showSuccess(_ message: String) {
        alertTitle = "Success"
        alertMessage = message
        showingPurchaseAlert = true
    }
    
    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showingErrorAlert = true
    }
}

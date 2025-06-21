//
//  PremiumSubscriptionView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI

// MARK: - Premium Subscription View
struct PremiumSubscriptionView: View {
    // MARK: - Properties
    @StateObject private var storeManager = StoreManager()
    @StateObject private var viewModel: PremiumViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    
    // MARK: - Initialization
    init() {
        let store = StoreManager()
        _storeManager = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: PremiumViewModel(storeManager: store))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.products.isEmpty {
                    LoadingView()
                } else {
                    ContentView()
                        .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton()
                }
            }
        }
        .task {
            await loadInitialData()
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingPurchaseAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("Retry") {
                Task { await viewModel.loadProducts() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

// MARK: - Private Views
private extension PremiumSubscriptionView {
    
    // MARK: - Background
    var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.blue).opacity(0.6),
                Color(.systemGray6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Close Button
    func CloseButton() -> some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Loading View
    func LoadingView() -> some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.primary)
            
            Text("Loading_Premium_Options...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content View
    func ContentView() -> some View {
        VStack(spacing: 0) {
            HeaderSection()
            
            Spacer()
            
            if !viewModel.hasAnyPremium {
                VStack(spacing: 16) {
//                    FeaturesSection()
                    SubscriptionPlansSection()
                    PurchaseButtonSection()
                }
            } else {
                PremiumActiveSection()
            }
            
            Spacer()
            
            FooterSection()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Header Section
    func HeaderSection() -> some View {
        
        VStack{
            VStack(spacing: 0) {
                Image("premium")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 400, maxHeight: 300)
                    .clipped()
//                    .clipShape(
//                        RoundedCorner(radius: 30, corners: [.bottomLeft, .bottomRight])
//                    )
                    .cornerRadius(20)
            }
            .edgesIgnoringSafeArea(.top)
            .ignoresSafeArea()
        }
//        VStack(spacing: 12) {
//            // Icon with animation
//            Image(systemName: viewModel.hasAnyPremium ? "checkmark.seal.fill" : "crown.fill")
//                .font(.system(size: 48, weight: .light))
//                .foregroundStyle(
//                    LinearGradient(
//                        colors: viewModel.hasAnyPremium
//                            ? [.green, .mint]
//                            : [.yellow, .orange],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .scaleEffect(isAnimating ? 1.1 : 1.0)
//                .animation(
//                    .easeInOut(duration: 2.0)
//                    .repeatForever(autoreverses: true),
//                    value: isAnimating
//                )
//                .onAppear { isAnimating = true }
//            
//            // Title
//            Text(viewModel.hasAnyPremium ? "Premium Active" : "Unlock Premium")
//                .font(.system(.title, design: .rounded, weight: .bold))
//                .multilineTextAlignment(.center)
//            
//            // Subtitle
//            Text(viewModel.hasAnyPremium
//                 ? "You have access to all premium features"
//                 : "Get unlimited access to all premium features")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .lineLimit(2)
//        }
    }
    
    // MARK: - Features Section
//    func FeaturesSection() -> some View {
//        VStack(spacing: 8) {
//            Text("Premium Features")
//                .font(.headline)
//                .fontWeight(.semibold)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            VStack(spacing: 6) {
//                CompactFeatureRow(icon: "star.fill", title: "Premium Content", color: .yellow)
//                CompactFeatureRow(icon: "bolt.fill", title: "Lightning Fast", color: .orange)
//                CompactFeatureRow(icon: "shield.fill", title: "Advanced Security", color: .blue)
//                CompactFeatureRow(icon: "cloud.fill", title: "Cloud Sync", color: .cyan)
//            }
//        }
//    }
    
    // MARK: - Subscription Plans Section
    func SubscriptionPlansSection() -> some View {
        VStack(spacing: 18) {
            Text("Choose_Your_Plan")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.products.isEmpty {
                CompactEmptyPlansView()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.products, id: \.id) { product in
                        CompactSubscriptionCard(
                            product: product,
                            isSelected: viewModel.selectedProduct?.id == product.id,
                            isPurchased: viewModel.isPurchased(product.id),
                            onTap: { viewModel.selectProduct(product) }
                        )
                        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedProduct?.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Plans View
    func CompactEmptyPlansView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundColor(.orange)
            
            Text("No_plans_available")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button("Retry") {
                Task { await viewModel.loadProducts() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Purchase Button Section
    func PurchaseButtonSection() -> some View {
        Button(action: handlePurchase) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(purchaseButtonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.isLoading && viewModel.selectedProduct != nil {
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(purchaseButtonBackground)
            .cornerRadius(12)
            .shadow(
                color: viewModel.selectedProduct != nil ? .blue.opacity(0.3) : .clear,
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .disabled(viewModel.selectedProduct == nil || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedProduct != nil)
    }
    
    // MARK: - Premium Active Section
    func PremiumActiveSection() -> some View {
        VStack(spacing: 16) {
            Text("🎉 You're all set!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enjoy all premium features without any limitations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Manage Subscription") {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Footer Section
    func FooterSection() -> some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task { await viewModel.restorePurchases() }
            }
            .foregroundColor(.blue)
            .font(.caption)
            .fontWeight(.medium)
            .disabled(viewModel.isLoading)
            
            HStack(spacing: 12) {
                Button("Terms") {
                    openTermsOfService()
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Button("Privacy") {
                    openPrivacyPolicy()
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Helper Methods
private extension PremiumSubscriptionView {
    
    func loadInitialData() async {
        await viewModel.loadProducts()
    }
    
    func handlePurchase() {
        guard viewModel.selectedProduct != nil else { return }
        Task {
            await viewModel.purchaseSelectedProduct()
        }
    }
    
    var purchaseButtonText: String {
        if let selectedProduct = viewModel.selectedProduct {
            return "Continue with \(selectedProduct.displayName)"
        } else {
            return "Select a Plan"
        }
    }
    
    var purchaseButtonBackground: LinearGradient {
        LinearGradient(
            colors: viewModel.selectedProduct != nil
                ? [.blue, .purple]
                : [.gray.opacity(0.6), .gray.opacity(0.4)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    func openTermsOfService() {
        // Implement terms of service URL opening
        if let url = URL(string: "https://yourapp.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        // Implement privacy policy URL opening
        if let url = URL(string: "https://yourapp.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Compact Feature Row Component
struct CompactFeatureRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .cornerRadius(6)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compact Subscription Card Component
struct CompactSubscriptionCard: View {
    let product: Any // Replace with your actual Product type
    let isSelected: Bool
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Plan") // Replace with product.displayName
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("$9.99/month") // Replace with product.price
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
//#if DEBUG
//struct PremiumSubscriptionView_Previews: PreviewProvider {
//    static var previews: some View {
//        PremiumSubscriptionView()
//            .preferredColorScheme(.light)
//        
//        PremiumSubscriptionView()
//            .preferredColorScheme(.dark)
//    }
//}
//#endif


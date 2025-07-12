//
//  PremiumSubscriptionView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//

import SwiftUI
import StoreKit

// MARK: - Premium Subscription View
struct PremiumSubscriptionView: View {
    // MARK: - Properties
    @StateObject private var storeManager = StoreManager()
    @StateObject private var viewModel: PremiumViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @State private var circleOffset = CGSize.zero
    @State var showPrivacyPolicy : Bool = false
    
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
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(colors: [Color.pink.opacity(0.4), Color.orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 280, height: 280)
                            .blur(radius: 100)
                            .opacity(0.4)
                            .offset(circleOffset)
                            .animation(
                                Animation.easeInOut(duration: 12)
                                    .repeatForever(autoreverses: true),
                                value: circleOffset
                            )
                            .onAppear {
                                circleOffset = CGSize(width: 80, height: -120)
                            }
                    )
                
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
        .sheet(isPresented: $showPrivacyPolicy, content: {
            PrivacyPolicyView()
        })
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
                Color.blue.opacity(0.9),
                Color.purple.opacity(0.85),
                Color.pink.opacity(0.8),
                Color.orange.opacity(0.7)
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
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
        }
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Loading View
    func LoadingView() -> some View {
        VStack(spacing: 30) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
            
            Text("Fetching Premium Options...")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
            
            ProgressView()
                .scaleEffect(1.7)
                .tint(.white)
            
            Button(action: {
                Task { await viewModel.loadProducts() }
            }) {
                Label("Retry", systemImage: "arrow.clockwise.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .shadow(color: Color.blue.opacity(0.7), radius: 8, x: 0, y: 3)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Content View
    func ContentView() -> some View {
        VStack(spacing: 32) {
            // Feature Highlights Scroll
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    CompactFeatureRow(icon: "bolt.fill", title: "Fast PDF Loads", color: .yellow)
                        .glassmorphicStyle()
                    CompactFeatureRow(icon: "lock.shield.fill", title: "Secure & Private", color: .blue)
                        .glassmorphicStyle()
                    CompactFeatureRow(icon: "sparkles", title: "Ad-Free Experience", color: .purple)
                        .glassmorphicStyle()
                    CompactFeatureRow(icon: "gearshape.fill", title: "Customizable UI", color: .pink)
                        .glassmorphicStyle()
                    CompactFeatureRow(icon: "star.fill", title: "Priority Support", color: .orange)
                        .glassmorphicStyle()
                }
                //.padding(.horizontal, 12)
            }
            .padding(.top, 45)
            .frame(height: 340)
            
//            HeaderSection()
            
//            Spacer()
            
            if !viewModel.hasAnyPremium {
                VStack(spacing: 24) {
                    SubscriptionPlansSection()
                    PurchaseButtonSection()
                        .padding(.horizontal, 0)
                }
            } else {
                PremiumActiveSection()
            }
            
//            Spacer()
            
            FooterSection()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Header Section
    func HeaderSection() -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.5), Color.pink.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 40)
                    .shadow(color: Color.pink.opacity(0.5), radius: 30, x: 0, y: 0)
                    .offset(y: 10)
                
                Image("premium")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 400, maxHeight: 300)
                    .clipped()
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.6), radius: 20, x: 0, y: 8)
            }
            
            VStack(spacing: 6) {
                Text("Go Premium!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                
                Text("Unlock all features and a better experience")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    
    // MARK: - Subscription Plans Section
    func SubscriptionPlansSection() -> some View {
        VStack(spacing: 22) {
            Text("Choose Your Plan")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            if viewModel.products.isEmpty {
                CompactEmptyPlansView()
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.products, id: \.id) { product in
                        CompactSubscriptionCard(
                            product: product,
                            isSelected: viewModel.selectedProduct?.id == product.id,
                            isPurchased: viewModel.isPurchased(product.id),
                            onTap: { viewModel.selectProduct(product) }
                        )
                        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedProduct?.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Plans View
    func CompactEmptyPlansView() -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .shadow(color: .orange.opacity(0.6), radius: 6, x: 0, y: 0)
            
            Text("Oops! No plans available at the moment.")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                Task { await viewModel.loadProducts() }
            }) {
                Label("Retry", systemImage: "arrow.clockwise.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [Color.orange.opacity(0.85), Color.red.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .shadow(color: Color.orange.opacity(0.7), radius: 8, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.15))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Purchase Button Section
    func PurchaseButtonSection() -> some View {
        Button(action: handlePurchase) {
            HStack(spacing: 14) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(purchaseButtonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                if !viewModel.isLoading && viewModel.selectedProduct != nil {
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.7), radius: 1, x: 0, y: 0)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if viewModel.selectedProduct != nil {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: .purple.opacity(0.8), radius: 12, x: 0, y: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 2
                                    )
                                    .blur(radius: 3)
                                    .offset(x: 1, y: 1)
                                    .mask(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [.black, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(
                                // subtle shining animation
                                ShineView()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.4))
                    }
                }
            )
            .scaleEffect(viewModel.selectedProduct != nil && isAnimating ? 1.05 : 1.0)
            .animation(viewModel.selectedProduct != nil ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isAnimating)
        }
        .disabled(viewModel.selectedProduct == nil || viewModel.isLoading)
        .onAppear {
            if viewModel.selectedProduct != nil {
                isAnimating = true
            } else {
                isAnimating = false
            }
        }
        .onChange(of: viewModel.selectedProduct) { newValue in
            if newValue != nil {
                isAnimating = true
            } else {
                isAnimating = false
            }
        }
    }
    
    // MARK: - Premium Active Section
    func PremiumActiveSection() -> some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Text("🎉")
                    .font(.system(size: 40))
                    .shadow(color: .yellow.opacity(0.8), radius: 6, x: 0, y: 0)
                
                Text("You're all set!")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 2)
            }
            
            Text("Enjoy all premium features without any limitations.")
                .font(.title3)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button("Manage Subscription") {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(Color.green)
//            .padding(.horizontal, 36)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: Color.green.opacity(0.7), radius: 14, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .blendMode(.overlay)
                    )
            )
            
        }
//        .padding(28)
//        .background(
//            ZStack {
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(
//                        LinearGradient(colors: [Color.green.opacity(0.25), Color.green.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
//                    )
//                RoundedRectangle(cornerRadius: 16)
//                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
//            }
//            .shadow(color: Color.green.opacity(0.5), radius: 20, x: 0, y: 8)
//            .blur(radius: 0.5)
//        )
//        .padding(.horizontal, 30)
    }
    
    // MARK: - Footer Section
    func FooterSection() -> some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await viewModel.restorePurchases() }
            }
            .foregroundColor(.white.opacity(0.9))
            .font(.caption)
            .fontWeight(.medium)
            .disabled(viewModel.isLoading)
            
            HStack(spacing: 14) {
                Button("Terms of Use") {
                    openTermsOfService()
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                Button("Privacy") {
                    openPrivacyPolicy()
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .onTapGesture {
                    showPrivacyPolicy = true
                }
            }
        }
        .padding(.bottom, 12)
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
    
    func openTermsOfService() {
        // Implement terms of service URL opening
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        // Implement privacy policy URL opening
        if let url = URL(string: "https://sites.google.com/view/smartpdftoolkit/home") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Shine View for Button Glow Animation
private struct ShineView: View {
    @State private var moveToRight: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.25), Color.white.opacity(0.0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width / 3, height: height * 2)
                .rotationEffect(Angle(degrees: 20))
                .offset(x: moveToRight ? width : -width, y: -height / 2)
                .animation(
                    Animation.linear(duration: 1.8)
                        .repeatForever(autoreverses: false),
                    value: moveToRight
                )
                .onAppear {
                    moveToRight = true
                }
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
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .frame(minWidth: 160)
    }
}

private extension View {
    func glassmorphicStyle() -> some View {
        self
            .background(
                BlurView(style: .systemMaterial)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(16)
                    .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// UIKit blur wrapper for SwiftUI
fileprivate struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
}

// MARK: - Compact Subscription Card Component
struct CompactSubscriptionCard: View {
    let product: SubscriptionProduct // Replace with your actual Product type
    let isSelected: Bool
    let isPurchased: Bool
    let onTap: () -> Void
    
    @State private var shineAnimation = false
    
    var body: some View {
        Button(action: {
            onTap()
            withAnimation(.easeInOut(duration: 0.3)) {
                shineAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    shineAnimation = false
                }
            }
        }) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .white : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        if product.displayName.lowercased().contains("year") {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .shadow(color: Color.orange.opacity(0.6), radius: 6, x: 0, y: 2)
                                )
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    
                    Text("\(product.price)")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                Spacer()
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.6), radius: 6, x: 0, y: 2)
                } else {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                            .shadow(color: Color.blue.opacity(0.6), radius: 10, x: 0, y: 4)
                    }
                    
                    if shineAnimation && isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.05), Color.white.opacity(0.25)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .mask(
                                RoundedRectangle(cornerRadius: 16)
                            )
                            .animation(.easeInOut(duration: 0.5), value: shineAnimation)
                            .transition(.opacity)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 0)
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

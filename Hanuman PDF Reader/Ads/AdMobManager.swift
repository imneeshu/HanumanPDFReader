//
//  AdMobManager.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 10/06/25.
//


import SwiftUI
import GoogleMobileAds

// MARK: - AdMob Manager
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    override init() {
        super.init()
        MobileAds.shared.start(completionHandler: nil)
    }
    
    func loadAd<T: AdLoaderDelegate & FullScreenContentDelegate>(
        for loader: T,
        adUnitID: String
    ) where T: ObservableObject {
        // Implementation handled by specific ad types
    }
}

// MARK: - Banner Ad View (Adaptive)
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let width: CGFloat

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        if uiView.adSize.size.width != width {
            uiView.adSize = adaptiveSize
            uiView.load(Request())
        }
    }
}

// MARK: - Interstitial Ad Manager
class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var isLoaded = false
    @Published var isPresenting = false
    
    private var interstitialAd: InterstitialAd?
    private let adUnitID: String
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }
    
    func loadAd() {
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let ad = ad {
                    self?.interstitialAd = ad
                    self?.interstitialAd?.fullScreenContentDelegate = self
                    self?.isLoaded = true
                } else {
                    self?.isLoaded = false
                }
            }
        }
    }
    
    func showAd() {
        guard let interstitialAd = interstitialAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        isPresenting = true
        interstitialAd.present(from: rootViewController)
    }
    
    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isPresenting = false
        loadAd() // Preload next ad
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isPresenting = false
        loadAd()
    }
}

// MARK: - Rewarded Ad Manager
class RewardedAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var isLoaded = false
    @Published var isPresenting = false
    @Published var rewardEarned = false
    
    private var rewardedAd: RewardedAd?
    private let adUnitID: String
    private var onReward: (() -> Void)?
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }
    
    func loadAd() {
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let ad = ad {
                    self?.rewardedAd = ad
                    self?.rewardedAd?.fullScreenContentDelegate = self
                    self?.isLoaded = true
                } else {
                    self?.isLoaded = false
                }
            }
        }
    }
    
    func showAd(onReward: @escaping () -> Void) {
        guard let rewardedAd = rewardedAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        self.onReward = onReward
        isPresenting = true
        
        rewardedAd.present(from: rootViewController) {
            DispatchQueue.main.async {
                self.rewardEarned = true
                onReward()
            }
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isPresenting = false
        loadAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isPresenting = false
        loadAd()
    }
}

// MARK: - Native Ad Manager
class NativeAdManager: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published var nativeAd: NativeAd?
    @Published var isLoaded = false
    
    private var adLoader: AdLoader?
    private let adUnitID: String
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }
    
    func loadAd() {
        adLoader = AdLoader(adUnitID: adUnitID, rootViewController: nil,
                              adTypes: [.native], options: nil)
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
    
    // MARK: - GADNativeAdLoaderDelegate
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAd = nativeAd
            self.isLoaded = true
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoaded = false
        }
    }
}

// MARK: - Native Ad View
//struct NativeAdView: UIViewRepresentable {
//    @ObservedObject var adManager: NativeAdManager
//    
//    func makeUIView(context: Context) -> NativeAdView {
//        let nativeAdView = NativeAdView(adManager: adManager)
//        return nativeAdView
//    }
//    
//    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
//        guard let nativeAd = adManager.nativeAd else { return }
//        
//        // Create a simple native ad layout
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 8
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        if let headline = nativeAd.headline {
//            let headlineLabel = UILabel()
//            headlineLabel.text = headline
//            headlineLabel.font = UIFont.boldSystemFont(ofSize: 16)
//            stackView.addArrangedSubview(headlineLabel)
//            nativeAdView.headlineView = headlineLabel
//        }
//        
//        if let body = nativeAd.body {
//            let bodyLabel = UILabel()
//            bodyLabel.text = body
//            bodyLabel.font = UIFont.systemFont(ofSize: 14)
//            bodyLabel.numberOfLines = 0
//            stackView.addArrangedSubview(bodyLabel)
//            nativeAdView.bodyView = bodyLabel
//        }
//        
//        if let callToAction = nativeAd.callToAction {
//            let ctaButton = UIButton(type: .system)
//            ctaButton.setTitle(callToAction, for: .normal)
//            ctaButton.backgroundColor = .systemBlue
//            ctaButton.setTitleColor(.white, for: .normal)
//            ctaButton.layer.cornerRadius = 8
//            ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
//            stackView.addArrangedSubview(ctaButton)
//            nativeAdView.callToActionView = ctaButton
//        }
//        
//        nativeAdView.addSubview(stackView)
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
//            stackView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
//            stackView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
//            stackView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -8)
//        ])
//        
//        nativeAdView.nativeAd = nativeAd
//    }
//}

// MARK: - SwiftUI Integration Views

// MARK: - SwiftUI AdBanner wrapper using GeometryReader for Adaptive Banner
struct AdBanner: View {
    let adUnitID: String
    init(_ adUnitID: String) {
        self.adUnitID = adUnitID
    }
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer(minLength: 0)
                BannerAdView(
                    adUnitID: adUnitID,
                    width: UIScreen.main.bounds.width
                )
                Spacer(minLength: 0)
            }
        }
        .frame(height: 50) // Let BannerAdView determine actual height
    }
}

struct InterstitialAdButton: View {
    @StateObject private var adManager: InterstitialAdManager
    let title: String
    let action: () -> Void
    
    init(_ title: String, adUnitID: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
        self._adManager = StateObject(wrappedValue: InterstitialAdManager(adUnitID: adUnitID))
    }
    
    var body: some View {
        Button(title) {
            if adManager.isLoaded {
                adManager.showAd()
                action()
            }
        }
        .disabled(!adManager.isLoaded || adManager.isPresenting)
    }
}

struct RewardedAdButton: View {
    @StateObject private var adManager: RewardedAdManager
    let title: String
    let onReward: () -> Void
    
    init(_ title: String, adUnitID: String, onReward: @escaping () -> Void) {
        self.title = title
        self.onReward = onReward
        self._adManager = StateObject(wrappedValue: RewardedAdManager(adUnitID: adUnitID))
    }
    
    var body: some View {
        Button(title) {
            if adManager.isLoaded {
                adManager.showAd(onReward: onReward)
            }
        }
        .disabled(!adManager.isLoaded || adManager.isPresenting)
    }
}

//struct NativeAd: View {
//    @StateObject private var adManager: NativeAdManager
//    
//    init(adUnitID: String) {
//        self._adManager = StateObject(wrappedValue: NativeAdManager(adUnitID: adUnitID))
//    }
//    
//    var body: some View {
//        Group {
//            if adManager.isLoaded {
////                NativeAdView(adManager: adManager)
////                    .frame(maxHeight: 200)
//            } else {
//                Rectangle()
//                    .fill(Color.gray.opacity(0.3))
//                    .frame(height: 100)
//                    .overlay(Text("Loading Ad..."))
//            }
//        }
//    }
//}

// MARK: - Usage Example
//struct ContentView: View {
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Text("AdMob SwiftUI Library Demo")
//                    .font(.title)
//                    .padding()
//                
//                // Banner Ad
//                AdBanner("ca-app-pub-3940256099942544/2934735716")
//                
//                // Interstitial Ad Button
//                InterstitialAdButton("Show Interstitial", 
//                                   adUnitID: "ca-app-pub-3940256099942544/4411468910") {
//                    print("Interstitial shown")
//                }
//                .buttonStyle(.borderedProminent)
//                
//                // Rewarded Ad Button
//                RewardedAdButton("Watch for Reward", 
//                               adUnitID: "ca-app-pub-3940256099942544/1712485313") {
//                    print("Reward earned!")
//                }
//                .buttonStyle(.bordered)
//                
////                // Native Ad
////                NativeAd(adUnitID: "ca-app-pub-3940256099942544/3986624511")
////                    .padding()
//                
//                Spacer()
//            }
//        }
//    }
//}

// MARK: - App Integration
//@main
//struct AdMobApp: App {
//    init() {
//        // Initialize AdMob
//        _ = AdMobManager.shared
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


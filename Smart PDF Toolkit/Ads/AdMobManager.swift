//
//  AdMobManager.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 10/06/25.
//

import SwiftUI
import GoogleMobileAds

let bannerAd : String = "ca-app-pub-5228443391218351/1240195322"
let interstitialAd : String = "ca-app-pub-5228443391218351/3170571704"

// MARK: - AdMob Manager
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    override init() {
        super.init()
        // Ensure the PDFs directory exists at app startup
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfsDirectory = documentsURL.appendingPathComponent("PDFs")
        if !fileManager.fileExists(atPath: pdfsDirectory.path) {
            do {
                try fileManager.createDirectory(at: pdfsDirectory, withIntermediateDirectories: true)
                print("PDFs directory created at app launch.")
            } catch {
                print("Failed to create PDFs directory: \(error)")
            }
        }
        // Optional: Create a test file to confirm write access
        let testFileURL = pdfsDirectory.appendingPathComponent("init_test.txt")
        let data = "App initialized at \(Date())".data(using: .utf8)
        fileManager.createFile(atPath: testFileURL.path, contents: data)
        
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
    @Binding var isLoaded: Bool

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdView
        init(parent: BannerAdView) { self.parent = parent }
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            parent.isLoaded = true
        }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.isLoaded = false
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UIView {
        if !isLoaded {
            // Return an empty UIView with zero frame when ad is not loaded
            return UIView(frame: .zero)
        }
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if !isLoaded {
            // Hide the banner view or set frame to zero when ad not loaded
            uiView.isHidden = true
            uiView.frame = .zero
            return
        }
        uiView.isHidden = false
        
        if let bannerView = uiView as? BannerView {
            let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: width)
            if bannerView.adSize.size.width != width {
                bannerView.adSize = adaptiveSize
                bannerView.load(Request())
            }
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
    
    func refreshAd(){
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
        guard let interstitialAd = interstitialAd else {
            print("[AdDebug] showAd(): interstitialAd is missing, returning.")
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("[AdDebug] showAd(): UIWindowScene not found, cannot present ad.")
            return
        }
        
        guard let rootViewController = windowScene.windows.first?.rootViewController else {
            print("[AdDebug] showAd(): rootViewController not found, cannot present ad.")
            return
        }
        
        // Check if already presenting to avoid multiple presentations
        guard !isPresenting else {
            print("[AdDebug] showAd(): Ad is already being presented.")
            return
        }
        
        print("[AdDebug] showAd(): Presenting interstitial ad now.")
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
    @Binding var bannerIsLoaded : Bool
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer(minLength: 0)
                BannerAdView(
                    adUnitID: adUnitID,
                    width: UIScreen.main.bounds.width,
                    isLoaded: $bannerIsLoaded
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
        self._adManager = StateObject(
            wrappedValue: InterstitialAdManager(adUnitID: interstitialAd)
        )
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

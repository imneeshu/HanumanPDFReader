//
//  Hanuman_PDF_ReaderApp.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

@main
struct Hanuman_PDF_ReaderApp: App {
    let persistenceController = PersistenceController.shared
    // Add interstitial ad manager
    var interstitialAdManager = InterstitialAdManager(adUnitID: interstitialAd)
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var mainViewModel = MainViewModel()
    init() {
        // Initialize AdMob
        _ = AdMobManager.shared
        importDefaultWelcomeGuideIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(mainViewModel: mainViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(interstitialAdManager)
                .environmentObject(settingsViewModel)
                .accentColor(settingsViewModel.isDarkMode ? .white : navy)
        }
    }
    
//    func importDefaultWelcomeGuideIfNeeded() {
//        let fileName = "WelcomeGuide.pdf"
//
//        // 1. Check if it's already in Core Data
//        if !mainViewModel.isFileAlreadySaved(named: fileName) {
//            if let bundleURL = Bundle.main.url(forResource: "WelcomeGuide", withExtension: "pdf") {
//                
//                // 2. Copy to Documents directory
//                let fileManager = FileManager.default
//                let destURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
//
//                do {
//                    if !fileManager.fileExists(atPath: destURL.path) {
//                        try fileManager.copyItem(at: bundleURL, to: destURL)
//                        
//                        // 3. Save to Core Data
//                        mainViewModel.saveInCoreData(fileURLs: [destURL])
//                    }
//                } catch {
//                    print("Failed to copy default PDF: \(error)")
//                }
//            }
//        }
//    }
    
    
    func importDefaultWelcomeGuideIfNeeded() {
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let storedAppVersion = UserDefaults.standard.string(forKey: "LastImportedVersion")

        // Run only if the app version changed
        guard storedAppVersion != currentAppVersion else { return }

        let fileName = "WelcomeGuide.pdf"

        if /*!mainViewModel.isFileAlreadySaved(named: fileName),*/
           let bundleURL = Bundle.main.url(forResource: "WelcomeGuide", withExtension: "pdf") {
            
            let fileManager = FileManager.default
            let destURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)

            do {
                if !fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.copyItem(at: bundleURL, to: destURL)
                    mainViewModel.saveInCoreData(fileURLs: [destURL])
                }
            } catch {
                print("Failed to copy default PDF: \(error)")
            }
        }

        // Update stored version so it doesn't run again
        if let currentAppVersion = currentAppVersion {
            UserDefaults.standard.set(currentAppVersion, forKey: "LastImportedVersion")
        }
    }


}

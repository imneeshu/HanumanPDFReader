//
//  SettingsViewModel.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import Combine
import SwiftUI

// MARK: - Settings Model
class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var keepScreenOn: Bool = false
    @Published var selectedLanguage: String = "en"
    @Published var notificationsEnabled: Bool = true
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        isDarkMode = userDefaults.bool(forKey: "isDarkMode")
        keepScreenOn = userDefaults.bool(forKey: "keepScreenOn")
        selectedLanguage = userDefaults.string(forKey: "selectedLanguage") ?? "en"
        notificationsEnabled = userDefaults.bool(forKey: "notificationsEnabled")
    }
    
    func saveSettings() {
        userDefaults.set(isDarkMode, forKey: "isDarkMode")
        userDefaults.set(keepScreenOn, forKey: "keepScreenOn")
        userDefaults.set(selectedLanguage, forKey: "selectedLanguage")
        userDefaults.set(notificationsEnabled, forKey: "notificationsEnabled")
    }
}

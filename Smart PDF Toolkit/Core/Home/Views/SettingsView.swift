//
//  SettingsView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//
//
//  SettingsView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showingLanguageSelection = false
    @Environment(\.presentationMode) var presentationMode
    @State var showPrivacyPolicyView : Bool = false
    
    var body: some View {
        NavigationView {
            
            List {
                Section("Appearance") {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(navy)
                        Text("Dark_Mode")
                        Spacer()
                        Toggle("", isOn: $settingsViewModel.isDarkMode)
                            .tint(navy)
                    }
                    .transition(.move(edge: .leading))
                    
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(navy)
                        Text("Keep_Screen_On")
                        Spacer()
                        Toggle("", isOn: $settingsViewModel.keepScreenOn)
                            .tint(navy)
                    }
                    .transition(.move(edge: .leading))
                }
                .transition(.move(edge: .leading))
                
//                Section("Language_") {
//                    HStack {
//                        Image(systemName: "globe")
//                            .foregroundColor(navy)
//                        Text("Language_")
//                        Spacer()
//                        Text(getLanguageDisplayName(settingsViewModel.selectedLanguage))
//                            .foregroundColor(.secondary)
//                            .transition(.slide)
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(navy)
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            showingLanguageSelection = true
//                        }
//                    }
//                    .transition(.move(edge: .leading))
//                }
//                .transition(.move(edge: .leading))
                
                Section("Notifications_") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(navy)
                        Text("Enable_Notifications")
                        Spacer()
                        Toggle("", isOn: $settingsViewModel.notificationsEnabled)
                    }
                    .transition(.move(edge: .leading))
                }
                .transition(.move(edge: .leading))
                
                Section("About_") {
                    SettingsRowView(
                        icon: "star.fill",
                        iconColor: navy,
                        title: NSLocalizedString("Rate_App", comment: ""),
                        action: {
                            // Open App Store rating
                            openAppStoreRating()
                        }
                    )
                    .transition(.move(edge: .leading))
                    
                    SettingsRowView(
                        icon: "square.and.arrow.up",
                        iconColor: navy,
                        title: NSLocalizedString("Share_App", comment: ""),
                        action: {
                            // Share app
                            shareApp()
                        }
                    )
                    .transition(.move(edge: .leading))
                    
                    SettingsRowView(
                        icon: "hand.raised.fill",
                        iconColor: navy,
                        title: NSLocalizedString("Privacy_Policy", comment: ""),
                        action: {
                            // Open privacy policy
                            showPrivacyPolicyView = true
                        }
                    )
                    .transition(.move(edge: .leading))
                    
//                    SettingsRowView(
//                        icon: "doc.text.fill",
//                        iconColor: navy,
//                        title: NSLocalizedString("Terms_of_Use", comment: ""),
//                        action: {
//                            // Open terms of use
//                            openURL("https://your-terms-url.com")
//                        }
//                    )
//                    .transition(.slide)
                }
                .transition(.slide)
                
                Section {
                    HStack {
                        Spacer()
                        Text("Version 1.1.1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .transition(.slide)
                }
                .transition(.move(edge: .leading))
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(.clear)
            .navigationTitle("Settings_")
            .navigationBarTitleDisplayMode(.large)
            // Add transition to the entire List
            .transition(.move(edge: .leading))
        }
        .padding()
        .navigationViewStyle(StackNavigationViewStyle())
        .background(settingsViewModel.isDarkMode ? Color.black : Color.white)
        // Add transition to NavigationView for view changes
        .transition(.move(edge: .leading))
        .sheet(isPresented: $showPrivacyPolicyView) {
            PrivacyPolicyView()
        }
//        .sheet(isPresented: $showingLanguageSelection) {
//            LanguageSelectionView(
//                selectedLanguage: $settingsViewModel.selectedLanguage,
//                isPresented: $showingLanguageSelection
//            )
//            // Sheet should slide from right to left
//            .transition(.move(edge: .bottom))
//        }
        .onChange(of: settingsViewModel.isDarkMode) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                settingsViewModel.saveSettings()
            }
        }
        .onChange(of: settingsViewModel.keepScreenOn) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                settingsViewModel.saveSettings()
                updateScreenOnSetting()
            }
        }
        .onChange(of: settingsViewModel.notificationsEnabled) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                settingsViewModel.saveSettings()
            }
        }
        .onChange(of: settingsViewModel.selectedLanguage) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                settingsViewModel.saveSettings()
            }
        }
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? "English"
    }
    
    private func updateScreenOnSetting() {
        UIApplication.shared.isIdleTimerDisabled = settingsViewModel.keepScreenOn
    }
    
    private func openAppStoreRating() {
        if let url = URL(string: "https://apps.apple.com/in/app/hanuman-pdf-reader/id6747693832?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareApp() {
        let text = "Check out this amazing PDF Reader Pro app!"
        let url = URL(string: "https://apps.apple.com/app/hanuman-pdf-reader/id6747693832")!
        let activityVC = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

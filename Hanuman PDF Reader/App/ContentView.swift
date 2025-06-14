//
//  ContentView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var mainViewModel = MainViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    @State private var selectedTab = 0
    @State private var animateHello = false
    @State private var contentOffset: CGFloat = 0
    @State private var tabBarOffset: CGFloat = 0
    @State private var previousTab = 0
    @State private var showingScanView = false
    @State private var showScannedViewPage = false
    @State private var showingImportView = false
    @State private var heightChange = 0
    @State private var capturedImages: [UIImage] = []
    @State private var isAutoCapture = false
    @State private var showingSettings = false // Added for settings sidebar
    @State var showOCRButton: Bool = true
    @State var isSearchPresented: Bool = false
    let tabTitles = ["Home", "Bookmarks", "Tools"]
    
    // Enhanced gradient colors
    let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.black,
            Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
            Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
            Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView{
        ZStack(alignment: .topLeading) {
            
            // Hidden NavigationLink triggered by state
            NavigationLink(
                destination: ScanToPDFView(
                    capturedImages: $capturedImages,
                    isAutoCapture: $isAutoCapture
                ),
                isActive: $showScannedViewPage,
                label: {
                    EmptyView() // No label shown
                }
            )
            
            // MARK: - Enhanced Gradient Background
            backgroundGradient
                .ignoresSafeArea()
                .overlay(
                    // Subtle animated overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(animateHello ? 0.1 : 0.05),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateHello)
                )
            
            VStack(spacing: 0) {
                
                // MARK: - Top Header with Settings and Search
                HStack {
                    // Settings button (left)
                    Button(action: {
                        withAnimation {
                            showingSettings = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.clear)
                    }
                    
                    Spacer()
                    
                    // Search button (right)
                    Button(action: {
                        // Search action
                        isSearchPresented = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                HStack(alignment: .center){
                    // MARK: - Animated Hello Label
                    Text("Manage & Edit Your PDFs")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .padding(.top, 10)
                        .opacity(animateHello ? 1 : 0.8)
                        .scaleEffect(animateHello ? 1.02 : 0.98)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: true), value: animateHello)
                        .onAppear { animateHello = true }
                }
                .padding(.bottom, 10)
                
                // MARK: - Action Buttons (Hide for Tools and Bookmarks)
                if selectedTab == 0 {
                    HStack(spacing: 16) {
                        // Left Column - Single iCloud Import Button
                        Button(action: {
                            // Import from iCloud action
                            showingImportView = true
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    // Gradient background with subtle shadow
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.15),
                                                    Color.white.opacity(0.4)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 160, height: 166) // Tall to match right column
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 18, x: 0, y: 4)
                                    
                                    VStack(spacing: 8) {
                                        // Icon with subtle background
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.black,
                                                            Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
                                                            Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
                                                            Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 55, height: 55)
                                                        
                                            Image(systemName: "icloud.and.arrow.down.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .frame(width: 56, height: 56)
                                                .background(Color.clear)
                                                .clipShape(Circle())
                                                .shadow(radius: 4)
                                            
                                        }
                                        
                                        Text("Import from")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                        
                                        Text("iCloud")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                        }
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: false)
                        
                        // Right Column - Two Buttons Vertically
                        VStack(spacing: 16) {
                            // Video/Image to PDF Button
                            Button(action: {}) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        // Gradient background with subtle shadow
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.15),
                                                        Color.white.opacity(0.4)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 160, height: 75)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 6) {
                                            // Icon with subtle background
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.black,
                                                                Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
                                                                Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
                                                                Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 45, height: 45)
                                                            
                                                Image(systemName: "video.fill")
                                                    .foregroundColor(.white)
                                                    .frame(width: 40, height: 40)
                                                    .background(Color.clear)
                                                    .clipShape(Circle())
                                                    .shadow(radius: 4)
                                            }
                                            
                                            Text("Image to PDF")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                }
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: false)
                            
                            // Scan Camera/Edit PDF Button
                            Button(action: {
                                // showingScanner = true
                            }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        // Gradient background with subtle shadow
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.15),
                                                        Color.white.opacity(0.4)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 160, height: 75)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 6) {
                                            // Icon with subtle background
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.black,
                                                                Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
                                                                Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
                                                                Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 45, height: 45)
                                                            
                                                Image(systemName: "camera.fill")
                                                    .foregroundColor(.white)
                                                    .frame(width: 40, height: 40)
                                                    .background(Color.clear)
                                                    .clipShape(Circle())
                                                    .shadow(radius: 4)
                                            }
                                            
                                            Text("Edit PDF")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                }
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                
                // MARK: - Content Container with Cool Transitions
                ZStack {
                    Group {
                        switch selectedTab {
                        case 0:
                            HomeView()
                                .onAppear{
                                    showOCRButton = true
                                }
                        case 1:
                            BookmarkView()
                                .frame(maxWidth: .infinity, maxHeight: 1000)
                                .onAppear{
                                    showOCRButton = false
                                }
                        case 2:
                            ToolsView()
                                .onAppear{
                                    showOCRButton = false
                                }
                        default: EmptyView()
                        }
                    }
                    .padding()
                    .background(.white)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    
                }
            }
            VStack{
                Spacer()
                // MARK: - Enhanced Custom Tab Bar (Reduced Height)
                HStack(spacing: 0) {
                    ForEach(0..<tabTitles.count, id: \.self) { index in
                        Button(action: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                previousTab = selectedTab
                                selectedTab = index
                                contentOffset = 0
                            }
                        }) {
                            VStack(spacing: 2) {
                                ZStack {
                                    // Background circle for selected tab
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.black,
                                                    Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
                                                    Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
                                                    Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                        .scaleEffect(selectedTab == index ? 1.0 : 0.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedTab)
                                    
                                    Image(systemName: tabIcon(for: index))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(selectedTab == index ? .white : Color.white.opacity(0.8))
                                        .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                                        .rotationEffect(.degrees(selectedTab == index ? 0 : -5))
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                                }
                                
                                Text(tabTitles[index])
                                    .font(.caption2)
                                    .fontWeight(selectedTab == index ? .bold : .medium)
                                    .foregroundColor(selectedTab == index ? .white : Color.white.opacity(0.7))
                                    .scaleEffect(selectedTab == index ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedTab == index ? Color.white.opacity(0.15) : Color.clear)
                                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
                                    Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
                                    Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, -5)
                .offset(y: tabBarOffset)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: tabBarOffset)
                
                AdBanner("ca-app-pub-3940256099942544/2934735716")
                    .padding(.bottom, 12)
            }
            .ignoresSafeArea()
            
            // MARK: - Settings Sidebar
               if showingSettings {
                   HStack(spacing: 0) {
                       // Settings View - Half screen width
                       SettingsView()
                            .frame(width: UIScreen.main.bounds.width / 1.3)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 0)
                            .animation(.easeOut(duration: 1.5))
                       
                       
                       // Transparent overlay to close settings when tapped
                       Color.black.opacity(0.3)
                           .onTapGesture {
                               withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                   showingSettings = false
                               }
                           }
                   }
                   .background(.clear)
                   .ignoresSafeArea()
               }
        }
        .overlay(
            Group {
                if showOCRButton {
                    // Floating Action Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingScanView = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.black,
                                                    Color(red: 0.18, green: 0.0, blue: 0.21),
                                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                                    Color(red: 0.8, green: 0.3, blue: 0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 55, height: 55)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.clear)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 110)
                        }
                    }
                } else {
                    EmptyView()
//                        .isHidden(true)
                }
            }
        )


    }
        .onChange(of: capturedImages, perform: { value in
            if !value.isEmpty{
                showScannedViewPage = true
                showingScanView = false
            }
        })
        .fullScreenCover(isPresented: $isSearchPresented) {
            SearchView(isPresented: $isSearchPresented)
        }
        
        .fileImporter(
            isPresented: $showingImportView,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                mainViewModel.saveInCoreData(fileURLs: urls)
                if let url = urls.first {
                    //                    selectedDirectory = url
                    
                }
            case .failure(let error):
                print("Directory selection failed: \(error)")
            }
        }
        
        .sheet(isPresented: $showingScanView) {
            CameraOCRView(
                capturedImages: $capturedImages,
                isAutoCapture: isAutoCapture
            )
        }
        .environmentObject(mainViewModel)
        .environmentObject(settingsViewModel)
        .preferredColorScheme(settingsViewModel.isDarkMode ? .dark : .light)
    }
    
    func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "clock.fill"
        case 2: return "bookmark.fill"
        case 3: return "wrench.and.screwdriver.fill"
        default: return "circle"
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

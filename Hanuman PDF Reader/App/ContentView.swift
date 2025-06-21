//
//  ContentView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

//// Enhanced gradient colors
//let backgroundGradient = LinearGradient(
//    gradient: Gradient(colors: [
//        Color.black,
//        Color(red: 0.18, green: 0.0, blue: 0.21), // Dark purple
//        Color(red: 0.6, green: 0.4, blue: 0.9),   // Original purple
//        Color(red: 0.8, green: 0.3, blue: 0.8)    // Original purple-pink
//    ]),
//    startPoint: .topLeading,
//    endPoint: .bottomTrailing
//)


let navy = Color(red: 0.047, green: 0.235, blue: 0.471)
let navyUIKit = UIColor(red: 0.047, green: 0.235, blue: 0.471, alpha: 1.0)

// White to blue gradient (90deg horizontal)
let backgroundGradient = LinearGradient(
    colors: [.clear, .clear],
    startPoint: .leading,
    endPoint: .trailing
)

let backgroundGradients = LinearGradient(
    colors: [.white, .white],
    startPoint: .leading,
    endPoint: .trailing
)
//LinearGradient(
//    gradient: Gradient(colors: [
//        Color(red: 0.306, green: 0.443, blue: 1.0),     // rgba(78, 113, 255, 1) at 0%
//        Color(red: 0.404, green: 0.733, blue: 0.902)    // rgba(103, 187, 230, 1) at 100%
//    ]),
//    startPoint: UnitPoint(x: 0.0, y: 0.2),
//    endPoint: UnitPoint(x: 1.0, y: 0.8)
//)//Color(red: 0.227, green: 0.349, blue: 0.820)

//LinearGradient(
//    gradient: Gradient(stops: [
//        .init(color: Color(red: 1.0, green: 1.0, blue: 1.0), location: 0.0),        // rgba(255, 255, 255, 1) at 0%
//        .init(color: Color(red: 0.286, green: 0.694, blue: 0.871), location: 0.53)  // rgba(73, 177, 222, 1) at 53%
//    ]),
//    startPoint: .bottom,
//    endPoint: .top
//)

let tabGradient =
LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.588, green: 0.816, blue: 0.922),  // rgba(150, 208, 235, 1) at 0%
        Color(red: 0.357, green: 0.675, blue: 0.812)   // rgba(91, 172, 207, 1) at 100%
    ]),
    startPoint: .leading,
    endPoint: .trailing
)

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
    @State var showImageView = false
    @State var selectedItems : [PhotoItem] = []
    @State var showImagePreview : Bool = false
    @State private var showSplash = true
    @State var showEditView: Bool = false
    
    @State private var showingPremium = false
    
    let tabTitles = ["Home_", "Bookmarks_", "Tools_"]
    
    var body: some View {
        ZStack {
            NavigationView{
                ZStack(alignment: .topLeading) {
                    
                    NavigationLink(
                        destination: ImageToPDFView(selectedItems: $selectedItems),
                        isActive: $showImagePreview,
                        label: {
                            EmptyView() // No label shown
                        }
                    )
                    
                    NavigationLink(
                        destination: HomeView(showEditView : $showEditView),
                        isActive: $showEditView,
                        label: {
                            EmptyView() // No label shown
                        }
                    )

                    
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
                    
                    NavigationLink(
                        destination: SearchView(isPresented: $isSearchPresented)
                            .navigationBarTitleDisplayMode(.inline),
                        isActive: $isSearchPresented,
                        label: { EmptyView() }
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
                                    .foregroundColor(navy)
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
                                    .foregroundColor(navy)
                                    .frame(width: 40, height: 40)
                                    .background(Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                            }
                            
                            // Search button (right)
                            Button(action: {
                                // Premium action
                                showingPremium = true
                            }) {
                                Image("premiumIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                                    .animation(.easeInOut(duration: 0.3), value: UUID())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        // MARK: - Action Buttons (Hide for Tools and Bookmarks)
                        if selectedTab == 0 {
                            HStack(alignment: .top, spacing: 12) {
                                // iCloud Import Button
                                Button(action: {
                                    // Import from iCloud action
                                    showingImportView = true
                                }) {
                                    ZStack {
                                        // Gradient background with subtle shadow
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(settingsViewModel.isDarkMode ? .black : .white)
                                            .frame(maxWidth: .infinity, maxHeight: 100)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 8) {
                                            // Icon with subtle background
                                            ZStack {
                                                Circle()
                                                    .fill(navy)
                                                    .frame(width: 40, height: 40)
                                                            
                                                Image(systemName: "icloud.and.arrow.down.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 4)
                                            }
                                            
                                            Text("\( NSLocalizedString("Import_from", comment: ""))\n\(NSLocalizedString("iCloud_", comment: "") )")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(settingsViewModel.isDarkMode ? .white : .black)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.1), value: false)
                                
                                // Image to PDF Button
                                Button(action: {
                                    showImageView = true
                                }) {
                                    ZStack {
                                        // Gradient background with subtle shadow
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(settingsViewModel.isDarkMode ? .black : .white)
                                            .frame(maxWidth: .infinity, maxHeight: 100)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 8) {
                                            // Icon with subtle background
                                            ZStack {
                                                Circle()
                                                    .fill(navy)
                                                    .frame(width: 40, height: 40)
                                                                
                                                Image(systemName: "video.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 4)
                                            }
                                            
                                            Text("Image_to_PDF")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(settingsViewModel.isDarkMode ? .white : .black)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.1), value: false)
                                
                                // Edit PDF Button
                                Button(action: {
                                    // showingScanner = true
                                }) {
                                    ZStack {
                                        // Gradient background with subtle shadow
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(settingsViewModel.isDarkMode ? .black : .white)
                                            .frame(maxWidth: .infinity, maxHeight: 100)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        
                                        VStack(spacing: 8) {
                                            // Icon with subtle background
                                            ZStack {
                                                Circle()
                                                    .fill(navy)
                                                    .frame(width: 40, height: 40)
                                                                
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 4)
                                            }
                                            
                                            Text("Edit_PDF")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(settingsViewModel.isDarkMode ? .white : .black)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                    .onTapGesture {
                                        showEditView = true
                                    }
                                }
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.1), value: false)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                            .padding(.bottom, 1)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        
                        // MARK: - Content Container with Cool Transitions
                        ZStack {
                            Group {
                                switch selectedTab {
                                case 0:
                                    HomeView(showEditView: $showEditView)
                                        .onAppear{
                                            showOCRButton = true
                                        }
                                        .padding(.bottom, 130)
                                case 1:
                                    BookmarkView(showEditView: $showEditView)
                                        .frame(maxWidth: .infinity, maxHeight: 1000)
                                        .onAppear{
                                            showOCRButton = false
                                        }
                                        .padding(.bottom, 130)
                                case 2:
                                    ToolsView()
                                        .onAppear{
                                            showOCRButton = false
                                        }
                                        .padding(.bottom, 130)
                                default: EmptyView()
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                            
                        }
                    }
                }
                .fullScreenCover(isPresented: $showImageView) {
                    PhotoGalleryView { selectedItems in
                        // Handle selected photos
                        self.selectedItems = selectedItems
                    }
                }
                .onChange(of: selectedItems, perform: { newValue in
                    showImagePreview = true
                })
                .navigationBarTitleDisplayMode(.large)
                    
                .overlay(
                    ZStack(alignment: .leading) {
                        if showingSettings {
                            // Dim background overlay
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .transition(.opacity)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showingSettings = false
                                    }
                                }
                        }
                        // Sidebar (always present for animation)
                        SettingsView()
                            .frame(width: UIScreen.main.bounds.width / 1.3, height: UIScreen.main.bounds.height)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 0)
                            .offset(x: showingSettings ? 0 : -UIScreen.main.bounds.width)
                            .opacity(showingSettings ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingSettings)
                            .ignoresSafeArea()
                    }
                    .animation(.easeInOut(duration: 0.2), value: showingSettings)
                )
                .overlay(
                    Group {
                        if showOCRButton && !showingSettings{
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
                                                    navy
//                                                    LinearGradient(
//                                                        gradient: Gradient(colors: [
//                                                            Color.black,
//                                                            Color(red: 0.18, green: 0.0, blue: 0.21),
//                                                            Color(red: 0.6, green: 0.4, blue: 0.9),
//                                                            Color(red: 0.8, green: 0.3, blue: 0.8)
//                                                        ]),
//                                                        startPoint: .topLeading,
//                                                        endPoint: .bottomTrailing
//                                                    )
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
                                    .padding(.bottom, 130)
                                }
                            }
                        } else {
                            EmptyView()
//                                .isHidden(true)
                        }
                    }
                )
                .overlay(alignment: .bottom) {
                    Group{
                        if !showingSettings{
                            AdBanner("ca-app-pub-3940256099942544/2934735716")
                                .frame(maxWidth: .infinity, maxHeight: 50)
                                .background(Color.clear)
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    Group{
                        if !showingSettings{
                            VStack(spacing: 0) {
                                // The tab bar code
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
                                                    Circle()
                                                        .fill(
                                                            navy
//                                                            LinearGradient(
//                                                                gradient: Gradient(colors: [
//                                                                    Color.black,
//                                                                    Color(red: 0.18, green: 0.0, blue: 0.21),
//                                                                    Color(red: 0.6, green: 0.4, blue: 0.9),
//                                                                    Color(red: 0.8, green: 0.3, blue: 0.8)
//                                                                ]),
//                                                                startPoint: .topLeading,
//                                                                endPoint: .bottomTrailing
//                                                            )
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
                                                Text(LocalizedStringKey(tabTitles[index]))
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
                                            navy
//                                            tabGradient
//                                            LinearGradient(
//                                                gradient: Gradient(colors: [
//                                                    Color.black,
//                                                    Color(red: 0.18, green: 0.0, blue: 0.21),
//                                                    Color(red: 0.6, green: 0.4, blue: 0.9),
//                                                    Color(red: 0.8, green: 0.3, blue: 0.8)
//                                                ]),
//                                                startPoint: .topLeading,
//                                                endPoint: .bottomTrailing
//                                            )
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                                .padding(.horizontal, 16)
                                .offset(y: tabBarOffset)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: tabBarOffset)
                                .padding(.bottom, 60) // 50(ad)+10(space)
                            }
                            .ignoresSafeArea(.all, edges: .horizontal)
                        }
                    }
                }
            }
            .onChange(of: capturedImages, perform: { value in
                if !value.isEmpty{
                    showScannedViewPage = true
                    showingScanView = false
                }
            })
            .fileImporter(
                isPresented: $showingImportView,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    mainViewModel.saveInCoreData(fileURLs: urls)
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
            
            if showSplash {
                EnhancedSplashScreenView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .fullScreenCover(isPresented: $showingPremium, content: {
            PremiumSubscriptionView()
        })
        .onAppear {
            if showSplash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
            }
        }
    }
    
    func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "bookmark.fill"
        case 2: return "wrench.and.screwdriver.fill"
        default: return "circle"
        }
    }
    
    func heightForTab(_ tab: Int) -> CGFloat {
        switch tab {
        case 0: return 600 // Example height for Home tab
        case 1: return 400 // Example height for Bookmark tab
        case 2: return 450 // Example height for Tools tab
        default: return 600
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


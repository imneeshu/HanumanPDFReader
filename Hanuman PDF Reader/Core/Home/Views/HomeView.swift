//
//  HomeView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//


//// Banner Ad
//AdBanner("ca-app-pub-3940256099942544/2934735716")
//
//// Interstitial Ad Button
//InterstitialAdButton("Show Interstitial", 
//                   adUnitID: "ca-app-pub-3940256099942544/4411468910") {
//    print("Interstitial shown")
//}
//.buttonStyle(.borderedProminent)
//
//// Rewarded Ad Button
//RewardedAdButton("Watch for Reward", 
//               adUnitID: "ca-app-pub-3940256099942544/1712485313") {
//    print("Reward earned!")
//}
//.buttonStyle(.bordered)

//import SwiftUI
//
//// MARK: - Home View
//struct HomeView: View {
//    @EnvironmentObject var viewModel: MainViewModel
//    @State private var showingSortSheet = false
//    @State private var showingFilterSheet = false
//    @State private var showingScanView = false
//    @State private var showingImportView = false
//    
//    var body: some View {
//        
//        NavigationView {
//            
//            VStack {
//                // Search Bar
//                SearchBar(text: $viewModel.searchText)
//                    .padding(.horizontal)
//                
//                // Filter and Sort Controls
//                HStack {
//                    Button("Filter") {
//                        showingFilterSheet = true
//                    }
//                    .foregroundColor(.blue)
//                    
//                    Spacer()
//                    
//                    Button("Sort") {
//                        showingSortSheet = true
//                    }
//                    .foregroundColor(.blue)
//                }
//                .padding(.horizontal)
//                
//                // File List
//                if viewModel.isLoading {
//                    ProgressView("Loading files...")
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else {
//                    FileListView(files: viewModel.fileItems)
//                }
//            }
////            .navigationTitle("Hanuman PDF Reader")
////            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(destination: SettingsView()) {
//                        Image(systemName: "gearshape.fill")
//                    }
//                }
//            }
//            .overlay(
//                // Floating Action Button
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            showingScanView = true
//                        }) {
//                            Image(systemName: "camera.fill")
//                                .font(.title2)
//                                .foregroundColor(.white)
//                                .frame(width: 56, height: 56)
//                                .background(Color.blue)
//                                .clipShape(Circle())
//                                .shadow(radius: 4)
//                        }
//                        .padding(.trailing, 20)
//                        .padding(.bottom, 20)
//                    }
//                }
//            )
//            
//            .overlay(
//                // Floating Action Button
//                VStack {
//                    Spacer()
//                    HStack {
//                        Button(action: {
//                            showingImportView = true
//                        }) {
//                            Image(systemName: "folder.fill.badge.plus")
//                                .font(.title2)
//                                .foregroundColor(.white)
//                                .frame(width: 56, height: 56)
//                                .background(Color.blue)
//                                .clipShape(Circle())
//                                .shadow(radius: 4)
//                        }
//                        .padding(.leading, 20)
//                        .padding(.bottom, 20)
//                        
//                        Spacer()
//                    }
//                }
//            )
//        }
//        .sheet(isPresented: $showingSortSheet) {
//            SortSelectionView(selectedSort: $viewModel.selectedSortType)
//        }
//        .sheet(isPresented: $showingFilterSheet) {
//            FilterSelectionView(selectedFileType: $viewModel.selectedFileType)
//        }
//        .sheet(isPresented: $showingScanView) {
//            ScanToPDFView()
//        }
//        
//        .fileImporter(
//            isPresented: $showingImportView,
//            allowedContentTypes: [.folder],
//            allowsMultipleSelection: false
//        ) { result in
//            switch result {
//            case .success(let urls):
//                viewModel.saveInCoreData(fileURLs: urls)
//                if let url = urls.first {
//                    //                    selectedDirectory = url
//                    
//                }
//            case .failure(let error):
//                print("Directory selection failed: \(error)")
//            }
//        }
//        .onAppear {
//            viewModel.loadFiles()
//        }
//    }
//    
//}





import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingSortSheet = false
    @State private var showingFilterSheet = false
    @State private var showingScanView = false
    @State private var showingImportView = false
    @Binding var showEditView: Bool
    
    var body: some View {
        VStack {
            // File List
            if viewModel.isLoading {
                ProgressView("Loading files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                FileListView(showEditView: $showEditView)
                    .environmentObject(viewModel)
            }
        }
//        .navigationTitle("Edit_PDF")
        .onAppear {
            viewModel.loadFiles()
        }
    }
    
}

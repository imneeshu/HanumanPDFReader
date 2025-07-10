//
//  RecentView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

// MARK: - Recent View
struct RecentView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                if viewModel.recentItems.isEmpty {
                    EmptyStateView(
                        title: "No Recent Files",
                        subtitle: "Files you've recently opened will appear here"
                    )
                } else {
                   // FileListView(files: viewModel.recentItems)
                }
            }
            .navigationTitle("Recent")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

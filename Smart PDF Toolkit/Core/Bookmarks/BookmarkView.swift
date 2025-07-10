//
//  BookmarkView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

// MARK: - Bookmark View
struct BookmarkView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var showEditView: Bool
    
    var body: some View {
        VStack {
            HStack{
                Text("Bookmarks_")
                    .font(.title)
                    .bold()
                Spacer()
            }
            if viewModel.bookmarkedItems.isEmpty {
                EmptyStateView(
                    title: "No Bookmarked Files",
                    subtitle: "Files you bookmark will appear here"
                )
            } else {
                FileListView(isBookmarked : true, showEditView : $showEditView)
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
}

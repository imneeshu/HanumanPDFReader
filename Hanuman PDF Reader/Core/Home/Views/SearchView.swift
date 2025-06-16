//
//  SearchView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 13/06/25.
//

import SwiftUI

struct SearchView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @EnvironmentObject var viewModel : MainViewModel
    @FocusState private var isSearchFieldFocused: Bool

    // Dummy data for demo
    let allItems = ["Apple", "Banana", "Orange", "Grapes", "Watermelon"]
    
    var searchedItems: [FileItem] {
        if searchText.isEmpty {
            return viewModel.fileItems
        } else {
            return viewModel.fileItems
                .filter {
                    $0.name!.localizedCaseInsensitiveContains(searchText)
                }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(
                        searchedItems,
                        id: \.objectID
                    ) { file in
                        FileRowView(file: file)
                            .onTapGesture {
                                viewModel.markAsRecentlyAccessed(file)
                            }
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search files...", text: $searchText)
                            .focused($isSearchFieldFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSearchFieldFocused ? navy : Color.gray.opacity(0.2), lineWidth: isSearchFieldFocused ? 2 : 1)
                            .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
        }
    }
}

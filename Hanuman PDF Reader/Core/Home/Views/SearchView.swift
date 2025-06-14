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
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject var viewModel : MainViewModel

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
            VStack {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isSearchFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isSearchFocused = true
                        }
                    }

                List {
                    ForEach(
                        searchedItems ,
                        id: \.objectID
                    ) { file in
                        FileRowView(file: file)
                            .onTapGesture {
                                viewModel.markAsRecentlyAccessed(file)
                            }
                            .cornerRadius(10)

                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle("Search", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

//
//  FileListView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

enum FilterType: String, CaseIterable {
    case lastViewed = "Last Viewed"
    case lastModified = "Last Modified"
    case name = "Name"
    case fileSize = "File Size"
    case fromNewtoOld = "Newest to Oldest"
    case fromOldtoNew = "Oldest to Newest"
}


import SwiftUI

// MARK: - File List View
struct FileListView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State var filterName : FilterType = .name
    @State var showSortSheet : Bool = false
    @State var isBookmarked : Bool = false
    @Binding var showEditView: Bool
    
    var body: some View {
        VStack{
            if viewModel.fileItems.isEmpty {
                EmptyStateView(
                    title: "No Files Found",
                    subtitle: "Add some documents to get started"
                )
            } else {
                if !isBookmarked && !showEditView{
                    HStack{
                        Text("\(NSLocalizedString("Sort_By", comment: "")) \(filterName.rawValue)")
                            .font(.subheadline.weight(.semibold))
                            .kerning(0.5)
                            .foregroundColor(.primary)
                    Image(systemName: "arrowtriangle.down.fill")
                        .resizable()
                        .frame(width: 8,height: 8)
                    Spacer()
                }
                    .onTapGesture {
                        showSortSheet = true
                    }
                    .padding()
            }
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(
                            isBookmarked ? viewModel.bookmarkedItems : viewModel.fileItems ,
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
                
                
            }
        }
        .sheet(isPresented: $showSortSheet) {
            SortOptionsSheet(
                isPresented: $showSortSheet,
                selectedSortOption : $filterName, localSelectedSortOption: filterName
            )
        }
        .onChange(of: filterName) { newValue in
            viewModel.filterAndSortFiles(fileType: filterName)
        }
    }
}




// MARK: - File List View
struct FileListViewForSearch: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State var filterName : FilterType = .name
    @State var showSortSheet : Bool = false
    @State var isBookmarked : Bool = false
    @State var fileItems : [FileItem] = []
    
    var body: some View {
        VStack{
            if viewModel.fileItems.isEmpty {
                EmptyStateView(
                    title: "No Files Found",
                    subtitle: "Add some documents to get started"
                )
            } else {
                if !isBookmarked{
                    HStack{
                        Text("\(NSLocalizedString("Sort_By", comment: "")) \(filterName.rawValue)")
                            .font(.caption)
                            .bold()
                        Image(systemName: "arrowtriangle.down.fill")
                            .resizable()
                            .frame(width: 8,height: 8)
                        Spacer()
                    }
                    .onTapGesture {
                        showSortSheet = true
                    }
                    .padding()
                }
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(
                            fileItems,
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
            }
        }
        .sheet(isPresented: $showSortSheet) {
            SortOptionsSheet(
                isPresented: $showSortSheet,
                selectedSortOption : $filterName, localSelectedSortOption: filterName
            )
        }
        .onChange(of: filterName) { newValue in
            viewModel.filterAndSortFiles(fileType: filterName)
        }
    }
}



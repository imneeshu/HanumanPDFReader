//
//  SortSelectionView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

// MARK: - Sort Selection View
struct SortSelectionView: View {
    @Binding var selectedSort: SortType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SortType.allCases, id: \.self) { sortType in
                    HStack {
                        Text(sortType.rawValue)
                        Spacer()
                        if selectedSort == sortType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSort = sortType
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

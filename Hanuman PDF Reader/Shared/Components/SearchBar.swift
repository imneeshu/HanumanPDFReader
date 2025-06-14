//
//  SearchBar.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search files...", text: $text)
                .padding(8)
                .cornerRadius(8)
                .foregroundColor(isFocused ? .blue : .black) // Animate text color
                .focused($isFocused)
                .animation(.easeInOut(duration: 0.3), value: isFocused) // Animate when focus changes
        }
        .padding(8)
        .cornerRadius(10)
    }
}

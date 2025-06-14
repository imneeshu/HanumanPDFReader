//
//  SortOption.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 12/06/25.
//


import SwiftUI

struct SortOption {
    let id = UUID()
    let title: FilterType
    let icon: String
}

struct SortOptionsSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedSortOption: FilterType
    @State var localSelectedSortOption: FilterType
    
    let sortOptions = [
        SortOption(title: .lastModified, icon: "clock"),
        SortOption(title: .lastViewed, icon: "eye"),
        SortOption(title: .name, icon: "textformat.abc"),
        SortOption(title: .fileSize, icon: "doc.text"),
        SortOption(title: .fromNewtoOld, icon: "arrow.down"),
        SortOption(title: .fromOldtoNew, icon: "arrow.up")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sort By")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Sort Options
                VStack(spacing: 0) {
                    ForEach(sortOptions, id: \.id) { option in
                        SortOptionRow(
                            option: option,
                            isSelected: localSelectedSortOption == option.title,
                            onTap: {
                                localSelectedSortOption = option.title
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Bottom Buttons
            HStack(spacing: 16) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Handle OK action here
                    print("Selected sort option: \(selectedSortOption)")
                    isPresented = false
                    selectedSortOption  = localSelectedSortOption
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
                                    Color(red: 0.6, green: 0.4, blue: 0.9),   // purple
                                    Color(red: 0.8, green: 0.3, blue: 0.8)    // pink-purple
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34) // Safe area padding
        }
        .background(Color(.systemBackground))
        .presentationDetents([.fraction(0.62)])
        .presentationDragIndicator(.visible)
    }
}

struct SortOptionRow: View {
    let option: SortOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
//                Image(systemName: option.icon)
//                    .font(.system(size: 18))
//                    .foregroundColor(.primary)
//                    .frame(width: 24, height: 24)
                
                Image(systemName: option.icon)
                    .frame(width: 40, height: 40)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .black,
                                Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
                                Color(red: 0.6, green: 0.4, blue: 0.9),
                                Color(red: 0.8, green: 0.3, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(Image(systemName: option.icon)) // mask the gradient to the icon shape
                    )
                    .background(.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(option.title.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

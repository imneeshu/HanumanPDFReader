//
//  PDFListView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

enum ListFlow{
    case split
    case merge
    case lock
    case unlock
}

struct PDFListView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var listFlow : ListFlow = .merge
    @Environment(\.presentationMode) var presentationMode
    
    let onClosePDF: () -> Void
    
    
    var body: some View {
        VStack {
            // File List
            if mainViewModel.isLoading {
                ProgressView("Loading files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                FileListViewForSelection(
                    listFlow: $listFlow,
                    onClosePDF: {
                        onClosePDF()
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                )
                    .environmentObject(mainViewModel)
            }
        }
        .onAppear {
            mainViewModel.loadFiles()
        }
    }
}

//#Preview {
//    PDFListView()
//}



// MARK: - Helper Functions
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

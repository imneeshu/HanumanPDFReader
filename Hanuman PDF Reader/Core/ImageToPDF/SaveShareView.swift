//
//  SaveShareView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 15/06/25.
//

import SwiftUI

struct SaveShareSheetContent: View {
    let pdfURL: URL
    let fileName: String
    let onViewPDF: () -> Void
    let onClosePDF: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var popToRoot = false
    @EnvironmentObject var settingsViewModel : SettingsViewModel

    var body: some View {
        NavigationView {
            SaveShareView(
                pdfURL: pdfURL,
                fileName: fileName,
                onViewPDF: onViewPDF,
                onClosePDF: onClosePDF,
                popToRoot: $popToRoot
            )
        }
//        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}

struct SaveShareView: View {
    let pdfURL: URL
    let fileName: String
    let onViewPDF: () -> Void
    let onClosePDF: () -> Void
    @Binding var popToRoot: Bool
    @State private var showingShareSheet = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showCheckmark = false
    @State var showingPreview : Bool = false
    @State var showingSaveShareView : Bool = false
    @EnvironmentObject var settingsViewModel : SettingsViewModel

    var body: some View {
        VStack(spacing: 25) {
            Spacer()

            // ✅ Checkmark animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.green)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .animation(.easeOut(duration: 0.6), value: showCheckmark)
            }
            .onAppear {
                showCheckmark = true
            }

            // ✅ Success message
            Text("PDF Created Successfully!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .transition(.opacity)
                .animation(.easeInOut, value: showCheckmark)

            Spacer()

            // ✅ Buttons
            VStack(spacing: 15) {
                // View PDF button
                Button(action: {
                    showingPreview = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View_PDF")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                // Share PDF button
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share_PDF")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        settingsViewModel.isDarkMode ? Color.white : Color.gray
                            .opacity(0.3)
                    )
                    .cornerRadius(12)
                }
                
                
                Button(action: {
                    showingSaveShareView = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save PDF to Files")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        settingsViewModel.isDarkMode ? Color.green : Color.green
                            .opacity(0.3)
                    )
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }

                // Close button (new)
                Button(action: {
                    popToRoot = true
                    presentationMode.wrappedValue.dismiss()
                    onClosePDF()
                }) {
                    Text("Close_")
                        .font(.headline)
                        .foregroundColor(
                            settingsViewModel.isDarkMode ? .white : .red
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(settingsViewModel.isDarkMode ? Color.red : Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .sheet(isPresented: $showingSaveShareView) {
                DocumentExportView(pdfURL: pdfURL)
        }
        .fullScreenCover(isPresented: $showingPreview) {
            DirectPDFView(fileURL: pdfURL) {
               print("URL")
            }
        }
        .padding()
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [pdfURL])
        }
    }
}

import SwiftUI
import PhotosUI

struct ScanToPDFView: View {
    @Binding var capturedImages: [UIImage]
    @Binding var isAutoCapture: Bool
    @State private var showCamera = false
    @State private var showRenameSheet = false
    @Environment(\.presentationMode) var presentationMode
    let onClosePDF: () -> Void
    @State private var pdfName: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "PDF_\(formatter.string(from: Date()))"
    }()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @EnvironmentObject var interstitialAdManager : InterstitialAdManager
    @State var showAd : Bool = false
    @State private var pendingPDFGeneration = false // Add this state

    var body: some View {
        VStack(spacing: 20) {
            if capturedImages.isEmpty {
                VStack(spacing: 12) {
                    Text("Scan_to_PDF")
                        .font(.largeTitle)
                        .bold()
                    Button("Start_Scanning") {
                        showCamera.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(capturedImages.indices, id: \.self) { index in
                            Image(uiImage: capturedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(10)
                        }
                        
                        // + Button Cell
                        Button(action: { showCamera = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 40, weight: .bold))
                                    .overlay(
                                        navy
                                        .mask(
                                            Image(systemName: "plus")
                                                .font(.system(size: 40, weight: .bold))
                                        )
                                    )
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(.gray.opacity(0.2))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    handleGeneratePDF()
                }) {
                    Text("Generate_PDF")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(navy)
                        .cornerRadius(12)
                }
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .padding(.top)
            }
        }
        // FIXED: Better ad handling with proper state management
        .onChange(of: interstitialAdManager.isPresenting) { isPresenting in
            if !isPresenting && pendingPDFGeneration && showAd {
                // Ad was dismissed and we have pending PDF generation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAd = false
                    pendingPDFGeneration = false
                    showRenameSheet = true
                    interstitialAdManager.refreshAd()
                }
            }
        }
//        .onDisappear {
//            capturedImages.removeAll()
//        }
        .padding()
        .navigationTitle("Scan To PDF")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraOCRView(capturedImages: $capturedImages, isAutoCapture: isAutoCapture)
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(
                pdfName: $pdfName,
                onCancel: {
                    showRenameSheet = false
                    resetAdState()
                },
                onDone: {
                    createPDF()
                    showRenameSheet = false
                    resetAdState()
                }
            )
            .presentationDetents([.fraction(0.30)])
        }
        .onChange(of: pdfURL) { newValue in
            if newValue != nil {
                showShareSheet = true
            }
        }
        .fullScreenCover(isPresented: $showShareSheet) {
            if let url = pdfURL {
                SaveShareSheetContent(
                    pdfURL: url,
                    fileName: "newFileName",
                    onViewPDF: {
                        // Add any additional navigation logic here if needed
                    },
                    onClosePDF: {
                        onClosePDF()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // FIXED: Proper ad handling function
    private func handleGeneratePDF() {
        if interstitialAdManager.isLoaded && !PremiumStatus.shared.isPremiumPurchased {
            pendingPDFGeneration = true
            showAd = true
            interstitialAdManager.showAd()
        } else {
            // No ad to show, go directly to rename sheet
            showRenameSheet = true
        }
    }
    
    // FIXED: Reset ad state properly
    private func resetAdState() {
        showAd = false
        pendingPDFGeneration = false
    }

    // Delayed PDF creation, uses updated name
    func createPDF() {
        let pdfCreator = PDFCreator(images: capturedImages, name: pdfName)
        pdfURL = pdfCreator.createPDF()
        savePDF(destinationURL: pdfURL!, fileName: pdfName, modificationDate: Date())
    }
}

// PDFConverter and RenameSheet remain the same
import PDFKit
import UIKit

struct PDFConverter {
    static func convertToImage(pdfData: Data) -> UIImage? {
        guard let document = PDFDocument(data: pdfData),
              let page = document.page(at: 0) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}

struct RenameSheet: View {
    @Binding var pdfName: String
    var onCancel: () -> Void
    var onDone: () -> Void
    @EnvironmentObject var settingsViewModel : SettingsViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Rename_PDF")
                .font(.title3)
                .bold()

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(navy, lineWidth: 2)
                    .background(Color.white)
                    .cornerRadius(12)
                    .frame(height: 40)

                TextField("PDF Name", text: $pdfName)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Color.clear)
                    .foregroundColor(.black)
            }
            .padding(.horizontal)

            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Text("Cancel_")
                        .foregroundColor(settingsViewModel.isDarkMode ? .white : .black)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray.opacity(0.2))
                        .cornerRadius(12)
                }
                .frame(width: UIScreen.main.bounds.width * 0.4)
                .padding(.top)
                
                Spacer()
                
                Button(action: {
                    onDone()
                }) {
                    Text("Done_")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(navy)
                        .cornerRadius(12)
                }
                .disabled(pdfName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(width: UIScreen.main.bounds.width * 0.4)
                .padding(.top)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

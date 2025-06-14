import SwiftUI
import PhotosUI

struct ScanToPDFView: View {
    @Binding var capturedImages: [UIImage]
    @Binding var isAutoCapture: Bool
    @State private var showCamera = false
    @State private var showRenameSheet = false
    @State private var pdfName: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "PDF_\(formatter.string(from: Date()))"
    }()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            if capturedImages.isEmpty {
                VStack(spacing: 12) {
                    Text("Scan to PDF")
                        .font(.largeTitle)
                        .bold()
                    Button("Start Scanning") {
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
                    showRenameSheet = true // Ask for name before creating PDF
                }) {
                    Text("Generate PDF")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.8, green: 0.3, blue: 0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .padding(.top)
            }
        }
        .onDisappear {
            capturedImages.removeAll()
        }
        .padding()
        .navigationTitle("Scan To PDF")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraOCRView(capturedImages: $capturedImages, isAutoCapture: isAutoCapture)
        }
        
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(
                pdfName: $pdfName,
                onCancel: { showRenameSheet = false },
                onDone: {
                    createPDF()
                    showRenameSheet = false
                }
            )
            .presentationDetents([.fraction(0.30)])
        }
        .onChange(of: pdfURL, perform: { newValue in
            if newValue != nil {
                showShareSheet = true
            }
        })
//        .alert("Rename PDF", isPresented: $showRenamePopup, actions: {
//            TextField("PDF Name", text: $pdfName)
//            
//            Button("Save to Files") {
//                createPDF()
//                if let url = pdfURL {
//                    showShareSheet = true
//                }
//            }
//            Button("Save to Photos") {
//                createPDF()
//                if let url = pdfURL,
//                   let data = try? Data(contentsOf: url),
//                   let pdfImage = PDFConverter.convertToImage(pdfData: data) {
//                    UIImageWriteToSavedPhotosAlbum(pdfImage, nil, nil, nil)
//                }
//            }
//            Button("Share") {
//                createPDF()
//                showShareSheet = true
//            }
//        }, message: {
//            Text("Enter a name for your PDF")
//        })
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    // Delayed PDF creation, uses updated name
    func createPDF() {
        let pdfCreator = PDFCreator(images: capturedImages, name: pdfName)
        pdfURL = pdfCreator.createPDF()
    }
}



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

    var body: some View {
        VStack(spacing: 20) {
            Text("Rename PDF")
                .font(.title3)
                .bold()

            ZStack {
                // Gradient border
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.6, green: 0.4, blue: 0.9),
                                Color(red: 0.8, green: 0.3, blue: 0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .background(Color.white)
                    .cornerRadius(12)
                    .frame(height: 40) // fixed height

                // TextField
                TextField("PDF Name", text: $pdfName)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(Color.clear)
            }
            .padding(.horizontal)



            HStack {
                Button(action: {
                    onCancel() // Ask for name before creating PDF
                }) {
                    Text("Cancel")
                        .foregroundColor(.black)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray.opacity(0.2))
                        .cornerRadius(12)
                }
                .disabled(pdfName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(width: UIScreen.main.bounds.width * 0.4)
                .padding(.top)
                Spacer()
                Button(action: {
                    onDone() // Ask for name before creating PDF
                }) {
                    Text("Done")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.8, green: 0.3, blue: 0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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

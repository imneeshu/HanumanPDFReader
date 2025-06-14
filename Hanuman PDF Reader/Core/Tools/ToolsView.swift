//
//  ToolsView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

// MARK: - Tools View
struct ToolsView: View {
    @State private var capturedImages: [UIImage] = []
    @State private var isAutoCapture = false
    @State private var showingScanView = false
    @State var showScannedViewPage: Bool = false
    
    var body: some View {
        ScrollView {
            
            NavigationLink(
                destination: ScanToPDFView(
                    capturedImages: $capturedImages,
                    isAutoCapture: $isAutoCapture
                ),
                isActive: $showScannedViewPage,
                label: {
                    EmptyView() // No label shown
                }
            )
            
            HStack{
                Text("Tools")
                    .font(.title)
                    .bold()
                    .padding()
                Spacer()
            }
            
            LazyVStack(spacing: 16) {
//                ToolCardView(
//                    title: "Scan to PDF",
//                    subtitle: "Capture documents with camera",
//                    icon: "camera.fill",
//                    color: .purple,
//                    destination: AnyView(CameraOCRView(capturedImages: $capturedImages, isAutoCapture: isAutoCapture))
//                )
                
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan to PDF")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Capture documents with camera")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    print("Neeshu is listening")
                    showingScanView = true
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                
                ToolCardView(
                    title: "Image to PDF",
                    subtitle: "Convert images to PDF",
                    icon: "photo.fill",
                    color: .purple,
                    destination: AnyView( PhotoGalleryView()/*ImageToPDFView()*/)
                )
                
                ToolCardView(
                    title: "Merge PDF",
                    subtitle: "Combine multiple PDFs",
                    icon: "doc.on.doc.fill",
                    color: .purple,
                    destination: AnyView(MergePDFView())
                )
                
                ToolCardView(
                    title: "Split PDF",
                    subtitle: "Extract pages from PDF",
                    icon: "scissors",
                    color: .purple,
                    destination: AnyView(SplitPDFView())
                )
                
                ToolCardView(
                    title: "Edit PDF",
                    subtitle: "Annotate and edit PDFs",
                    icon: "pencil.circle.fill",
                    color: .purple,
                    destination: AnyView(EditPDFView())
                )
            }
            .padding()
        }
        .sheet(isPresented: $showingScanView) {
            CameraOCRView(
                capturedImages: $capturedImages,
                isAutoCapture: isAutoCapture
            )
        }
        .onChange(of: capturedImages, perform: { newValue in
            if capturedImages.isEmpty {
                showScannedViewPage = false
            }
            else{
                showScannedViewPage = true
            }
        })
        .navigationBarTitleDisplayMode(.large)
    }
}

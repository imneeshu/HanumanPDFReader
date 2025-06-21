//
//  ToolsView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI
import PhotosUI

// MARK: - Tools View
struct ToolsView: View {
    @State private var capturedImages: [UIImage] = []
    @State private var isAutoCapture = false
    @State private var showingScanView = false
    @State var showScannedViewPage: Bool = false
    @State var selectedItems: [PhotoItem] = []
    @State var showImageView: Bool = false
    @State var showImagePreview : Bool = false
    @State var showEditView: Bool = true
    
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
            
            NavigationLink(
                destination: ImageToPDFView(selectedItems: $selectedItems),
                isActive: $showImagePreview,
                label: {
                    EmptyView() // No label shown
                }
            )
            
            HStack{
                Text("Tools_")
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
                            navy
//                            LinearGradient(
//                                gradient: Gradient(colors: [
//                                    Color.black,
//                                    Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
//                                    Color(red: 0.6, green: 0.4, blue: 0.9),   // purple
//                                    Color(red: 0.8, green: 0.3, blue: 0.8)    // pink-purple
//                                ]),
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan_to_PDF")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Scan_Sub")
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
                
                
                
                HStack {
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            navy
//                            LinearGradient(
//                                gradient: Gradient(colors: [
//                                    Color.black,
//                                    Color(red: 0.18, green: 0.0, blue: 0.21), // dark purple
//                                    Color(red: 0.6, green: 0.4, blue: 0.9),   // purple
//                                    Color(red: 0.8, green: 0.3, blue: 0.8)    // pink-purple
//                                ]),
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image_to_PDF")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Image_Sub")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    print("Neeshu is listening")
                    showImageView = true
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                
//                ToolCardView(
//                    title: "Image to PDF",
//                    subtitle: "Convert images to PDF",
//                    icon: "photo.fill",
//                    color: .purple,
//                    destination: AnyView( PhotoGalleryView { selectedItems in
//                        // Handle selected photos
//                        self.selectedItems = selectedItems
//                    }/*ImageToPDFView()*/)
//                )
                
                ToolCardView(
                    title: NSLocalizedString("Merge_PDF", comment: ""),
                    subtitle: NSLocalizedString("Merge_Sub", comment: ""),
                    icon: "doc.on.doc.fill",
                    color: navy,
                    destination: AnyView(
                        PDFListView(listFlow: .merge)/*MergePDFView()*/
                    )
                )
                
                ToolCardView(
                    title: NSLocalizedString("Split_PDF", comment: ""),
                    subtitle: NSLocalizedString("Split_Sub", comment: ""),
                    icon: "scissors",
                    color: navy,
                    destination: AnyView(PDFListView(listFlow: .split))
                )
                
                ToolCardView(
                    title:  NSLocalizedString("Edit_PDF", comment: ""),
                    subtitle: NSLocalizedString("Edit_Sub", comment: ""),
                    icon: "pencil.circle.fill",
                    color: navy,
                    destination: AnyView(HomeView(showEditView: $showEditView))
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
        .fullScreenCover(isPresented: $showImageView) {
            PhotoGalleryView { selectedItems in
                // Handle selected photos
                self.selectedItems = selectedItems
            }
        }
        .onChange(of: selectedItems, perform: { newValue in
            showImagePreview = true
        })
        .navigationBarTitleDisplayMode(.large)
    }
}

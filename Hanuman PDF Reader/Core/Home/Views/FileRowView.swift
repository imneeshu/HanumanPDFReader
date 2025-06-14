//
//  FileRowView.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

struct FileRowView: View {
    var file: FileItem
    @EnvironmentObject var viewModel: MainViewModel

    @State private var showingRenameAlert = false
    @State private var showingDeleteAlert = false
    @State private var newFileName = ""
    @State  var previewError: String?
    @State private var showingPreview = false
    @State private var fileURLForPreview: URL?

    var body: some View {
        VStack{
            contentRow
                .alert("Rename File", isPresented: $showingRenameAlert) {
                    TextField("New name", text: $newFileName)
                    Button("Cancel", role: .cancel) { }
                    Button("Rename") {
                        if !newFileName.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.renameFile(file, newName: newFileName)
                        }
                    }
                }
                .alert("Delete File", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        viewModel.deleteFile(file)
                        viewModel.fetchFilesFromCoreData()
                    }
                } message: {
                    Text("This action cannot be undone.")
                }
                .alert("Error", isPresented: Binding<Bool>(
                    get: { previewError != nil },
                    set: { if !$0 { previewError = nil } }
                )) {
                    Button("OK", role: .cancel) {
                        previewError = nil
                    }
                } message: {
                    if let error = previewError {
                        Text(error)
                    }
                }
                .fullScreenCover(isPresented: $showingPreview) {
                    if let url = fileURLForPreview {
//                        FilePreviewView(fileURL: url) {
//                            fileURLForPreview = nil
//                        }
                        DirectPDFView(fileURL: url) {
                            fileURLForPreview = nil
                        }
                    } else {
                        // Fallback view if URL is nil
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("File Not Found")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Unable to locate the file for preview")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Close") {
                                fileURLForPreview = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
        }
    }

    // MARK: - File Row Content
    private var contentRow: some View {
        HStack(spacing: 12) {
            fileTypeIcon
                .frame(width: 40, height: 40)
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
                    .mask(fileTypeIcon) // mask the gradient to the icon shape
                )
                .background(fileTypeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))


            VStack(alignment: .leading, spacing: 4) {
                Text(file.name ?? "Unknown")
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Text(file.fileTypeEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(fileTypeColor.opacity(0.2))
                        .clipShape(Capsule())

                    Spacer()

                    if let modifiedDate = file.modifiedDate {
                        Text(formatDate(modifiedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button {
                viewModel.toggleBookmark(for: file)
            } label: {
                Image(systemName: file.isBookmarked ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
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
                            Image(systemName: file.isBookmarked ? "bookmark.fill" : "bookmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        )
                    )

            }
            .buttonStyle(.plain)
        }
        .onChange(of: fileURLForPreview, perform: { newValue in
            if newValue == nil {
                self.showingPreview = false
            }
            else{
                self.showingPreview = true
            }
        })
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes entire row tappable
        .contextMenu { contextMenuItems }
        .onTapGesture {
            validateAndShowPreview()
        }
    }

    // MARK: - File Helpers

    private func createFileURL() -> URL? {
        guard let path = file.path,
              let fileURL = URL(string: path),
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return fileURL
    }


    private func validateAndShowPreview() {
        guard let primaryURL = createFileURL() else {
            fallbackFileLookup()
            return
        }

        downloadICloudFileIfNeeded(at: primaryURL) { success in
            DispatchQueue.main.async {
                if success {
                    fileURLForPreview = primaryURL
                } else {
                    previewError = "Could not download file from iCloud."
                }
            }
        }
    }

    func fallbackFileLookup() {
        let correctFileName = file.name ?? ""
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let iCloudDir = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")

        let altPaths: [String] = [
            file.path,
            docDir.appendingPathComponent(correctFileName).path,
            downloadsDir.appendingPathComponent(correctFileName).path,
            iCloudDir?.appendingPathComponent(correctFileName).path
        ].compactMap { $0 }

        var foundURL: URL?

        for path in altPaths {
            print("Checking alt path: \(path)")
            if FileManager.default.fileExists(atPath: path) {
                print("✅ File exists at: \(path)")
                foundURL = URL(fileURLWithPath: path)
                break
            } else {
                print("❌ File does not exist at: \(path)")
            }
        }

        if let url = foundURL {
            fileURLForPreview = url
        } else {
            previewError = """
            File not found at any known locations.
            Tried:
            • \(altPaths.joined(separator: "\n• "))
            """
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            newFileName = file.name ?? ""
            showingRenameAlert = true
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            shareFile()
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Button {
            viewModel.toggleBookmark(for: file)
        } label: {
            Label(
                file.isBookmarked ? "Remove Bookmark" : "Add Bookmark",
                systemImage: file.isBookmarked ? "bookmark.slash" : "bookmark"
            )
        }

        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Icons and Styling

    private var fileTypeIcon: some View {
        Image(systemName: file.fileTypeEnum.iconName)
            .font(.title2)
            .foregroundColor(fileTypeColor)
    }

    private var fileTypeColor: Color {
        switch file.fileTypeEnum {
        case .pdf: return .purple
        case .word: return .blue
        case .excel: return .green
        case .powerpoint: return .orange
        }
    }

    // MARK: - File Actions

    private func shareFile() {
        guard let url = createFileURL() else { return }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    func downloadICloudFileIfNeeded(at url: URL, completion: @escaping (Bool) -> Void) {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
            let isUbiquitous = resourceValues.isUbiquitousItem ?? false

            if isUbiquitous {
                print("File is in iCloud. Trying to download...")

                do {
                    try FileManager.default.startDownloadingUbiquitousItem(at: url)
                    print("Download started.")
                    completion(true)
                } catch {
                    print("Download failed: \(error.localizedDescription)")
                    completion(false)
                }

            } else {
                print("File is local.")
                completion(true)
            }
        } catch {
            print("Error checking iCloud status: \(error.localizedDescription)")
            completion(false)
        }
    }
}

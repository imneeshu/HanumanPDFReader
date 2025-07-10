//////
//////  FileManagerService.swift
//////  Hanuman PDF Reader
//////
//////  Created by Neeshu Kumar on 05/06/25.
//////

import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - FileType Enum
enum FileType: String, CaseIterable {
    case pdf
    case word
    case excel
    case powerpoint

    var fileExtensions: [String] {
        switch self {
        case .pdf: return ["pdf"]
        case .word: return ["doc", "docx"]
        case .excel: return ["xls", "xlsx"]
        case .powerpoint: return ["ppt", "pptx"]
        }
    }

    var utTypes: [UTType] {
        switch self {
        case .pdf:
            return [.pdf]
        case .word:
            return [
                UTType(filenameExtension: "doc") ?? .data,
                UTType(filenameExtension: "docx") ?? .data
            ]
        case .excel:
            return [
                UTType(filenameExtension: "xls") ?? .data,
                UTType(filenameExtension: "xlsx") ?? .data
            ]
        case .powerpoint:
            return [
                UTType(filenameExtension: "ppt") ?? .data,
                UTType(filenameExtension: "pptx") ?? .data
            ]
        }
    }

    var iconName: String {
        switch self {
        case .pdf: return "doc.richtext.fill"
        case .word: return "doc.text.fill"
        case .excel: return "tablecells.fill"
        case .powerpoint: return "play.rectangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pdf: return .red
        case .word: return .blue
        case .excel: return .green
        case .powerpoint: return .orange
        }
    }

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .word: return "Word"
        case .excel: return "Excel"
        case .powerpoint: return "PowerPoint"
        }
    }
}

// MARK: - Enhanced FileManagerService with Directory Selection
class FileManagerService: NSObject, ObservableObject {
    static let shared = FileManagerService()
    private let fileManager = FileManager.default
    
    @Published var availableFiles: [URL] = []
    @Published var isImporting = false
    @Published var importProgress = 0.0
    @Published var selectedDirectory: URL?
    
    private override init() {
        super.init()
        loadSelectedDirectory()
    }
    
    // MARK: - Directory Management
    func getDocumentsDirectory() -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
    }
    
    func getDownloadsDirectory() -> URL? {
        return fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }
    
    func getInboxDirectory() -> URL {
        let documentsURL = getDocumentsDirectory()
        let inboxURL = documentsURL.appendingPathComponent("Inbox")
        
        if !fileManager.fileExists(atPath: inboxURL.path) {
            try? fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        }
        
        return inboxURL
    }
    
    func getAvailableDirectories() -> [URL] {
        var directories: [URL] = []
        
        // Always include documents directory
        directories.append(getDocumentsDirectory())
        
        // Include inbox directory
        directories.append(getInboxDirectory())
        
        // Include downloads directory if available
        if let downloadsURL = getDownloadsDirectory(),
           fileManager.fileExists(atPath: downloadsURL.path) {
            directories.append(downloadsURL)
        }
        
        // Load custom directories from UserDefaults
        if let savedPaths = UserDefaults.standard.array(forKey: "availableDirectories") as? [String] {
            let customDirectories = savedPaths.compactMap { path -> URL? in
                let url = URL(fileURLWithPath: path)
                return fileManager.fileExists(atPath: url.path) ? url : nil
            }
            directories.append(contentsOf: customDirectories)
        }
        
        return directories
    }
    
    func setSelectedDirectory(_ directory: URL) {
        selectedDirectory = directory
        UserDefaults.standard.set(directory.path, forKey: "selectedDirectory")
        refreshFiles()
    }
    
    private func loadSelectedDirectory() {
        if let savedPath = UserDefaults.standard.string(forKey: "selectedDirectory") {
            let url = URL(fileURLWithPath: savedPath)
            if fileManager.fileExists(atPath: url.path) {
                selectedDirectory = url
                return
            }
        }
        
        // Default to documents directory
        selectedDirectory = getDocumentsDirectory()
    }
    
    // MARK: - File Discovery
    func getAllFiles() -> [URL] {
        guard let directory = selectedDirectory else {
            return []
        }
        
        return getFilesFromDirectory(directory).sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    private func getFilesFromDirectory(_ directory: URL) -> [URL] {
        var files: [URL] = []
        
        guard fileManager.fileExists(atPath: directory.path) else {
            return files
        }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                options: .skipsHiddenFiles
            )
            
            for url in fileURLs {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                
                if resourceValues.isDirectory == true {
                    // Recursively search subdirectories
                    files.append(contentsOf: getFilesFromDirectory(url))
                } else {
                    let fileExtension = url.pathExtension.lowercased()
                    if FileType.allCases.flatMap({ $0.fileExtensions }).contains(fileExtension) {
                        files.append(url)
                    }
                }
            }
        } catch {
            print("Error getting files from \(directory): \(error.localizedDescription)")
        }
        
        return files
    }
    
    // MARK: - File Import
    func importFiles(from urls: [URL], to destinationDirectory: URL? = nil) {
        isImporting = true
        
        let destination = destinationDirectory ?? selectedDirectory ?? getDocumentsDirectory()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let totalFiles = urls.count
            
            for (index, url) in urls.enumerated() {
                _ = self.importFile(from: url, to: destination)
                
                DispatchQueue.main.async {
                    self.importProgress = Double(index + 1) / Double(totalFiles)
                }
            }
            
            DispatchQueue.main.async {
                self.isImporting = false
                self.importProgress = 0.0
                self.refreshFiles()
            }
        }
    }
    
    private func importFile(from sourceURL: URL, to destinationDirectory: URL) -> URL? {
        guard sourceURL.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource")
            return nil
        }
        
        defer {
            sourceURL.stopAccessingSecurityScopedResource()
        }
        
        let fileName = sourceURL.lastPathComponent
        let destinationURL = destinationDirectory.appendingPathComponent(fileName)
        let finalDestinationURL = getUniqueFileURL(for: destinationURL)
        
        do {
            // Ensure destination directory exists
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            
            try fileManager.copyItem(at: sourceURL, to: finalDestinationURL)
            return finalDestinationURL
        } catch {
            print("Error importing file: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getUniqueFileURL(for url: URL) -> URL {
        var finalURL = url
        var counter = 1
        
        while fileManager.fileExists(atPath: finalURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newName = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            finalURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        
        return finalURL
    }
    
    // MARK: - File Operations
    func deleteFile(at url: URL) -> Bool {
        do {
            try fileManager.removeItem(at: url)
            refreshFiles()
            return true
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
            return false
        }
    }
    
    func refreshFiles() {
        DispatchQueue.global(qos: .userInitiated).async {
            let files = self.getAllFiles()
            DispatchQueue.main.async {
                self.availableFiles = files
            }
        }
    }
    
    // MARK: - File Information
    func getFileType(for url: URL) -> FileType {
        let fileExtension = url.pathExtension.lowercased()
        for fileType in FileType.allCases {
            if fileType.fileExtensions.contains(fileExtension) {
                return fileType
            }
        }
        return .pdf
    }
    
    func getFileSize(for url: URL) -> Int64 {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resources.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    func getModificationDate(for url: URL) -> Date {
        do {
            let resources = try url.resourceValues(forKeys: [.contentModificationDateKey])
            return resources.contentModificationDate ?? Date()
        } catch {
            return Date()
        }
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func isFileAccessible(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path) && fileManager.isReadableFile(atPath: url.path)
    }
    
    // MARK: - Directory Information
    func getDirectoryFileCount(for directory: URL) -> Int {
        return getFilesFromDirectory(directory).count
    }
    
    func getDirectorySize(for directory: URL) -> Int64 {
        let files = getFilesFromDirectory(directory)
        return files.reduce(0) { total, url in
            return total + getFileSize(for: url)
        }
    }
    
    func isDirectoryAccessible(_ directory: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

// MARK: - Document Picker Wrapper
struct DocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var fileManager: FileManagerService
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes = FileType.allCases.flatMap { $0.utTypes }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.fileManager.importFiles(from: urls)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}






































////
////
////import SwiftUI
////import CoreData
////import Combine
////
////// MARK: - File Manager
////class FileManagerService: ObservableObject {
////    static let shared = FileManagerService()
////    private let fileManager = FileManager.default
////    
////    private init() {}
////    
////    func getDocumentsDirectory() -> URL {
////        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
////        return documentsURL
////    }
////
////    func getAllFiles() -> [URL] {
////        var allFiles: [URL] = []
////
////        let documentsURL = getDocumentsDirectory()
////        var searchDirectories = [documentsURL]
////
////        // Try to get Downloads directory, and check if it exists
////        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first,
////           fileManager.fileExists(atPath: downloadsURL.path) {
////            searchDirectories.append(downloadsURL)
////        }
////
////        for directory in searchDirectories {
////            do {
////                let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles)
////                let filtered = fileURLs.filter { url in
////                    let fileExtension = url.pathExtension.lowercased()
////                    return FileType.allCases.flatMap { $0.fileExtensions }.contains(fileExtension)
////                }
////                allFiles.append(contentsOf: filtered)
////            } catch {
////                print("Error getting files from \(directory): \(error)")
////            }
////        }
////
////        return allFiles
////    }
////
////
////    
////    func getFileType(for url: URL) -> FileType {
////        let fileExtension = url.pathExtension.lowercased()
////        for fileType in FileType.allCases {
////            if fileType.fileExtensions.contains(fileExtension) {
////                return fileType
////            }
////        }
////        return .pdf
////    }
////    
////    func getFileSize(for url: URL) -> Int64 {
////        do {
////            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
////            return Int64(resources.fileSize ?? 0)
////        } catch {
////            return 0
////        }
////    }
////    
////    func getModificationDate(for url: URL) -> Date {
////        do {
////            let resources = try url.resourceValues(forKeys: [.contentModificationDateKey])
////            return resources.contentModificationDate ?? Date()
////        } catch {
////            return Date()
////        }
////    }
////}
////
////
////
////// MARK: - FileType Extension for UI
////extension FileType {
////    var iconName: String {
////        switch self {
////        case .pdf: return "doc.richtext.fill"
////        case .word: return "doc.text.fill"
////        case .excel: return "tablecells.fill"
////        case .powerpoint: return "play.rectangle.fill"
////        }
////    }
////    
////    var color: Color {
////        switch self {
////        case .pdf: return .red
////        case .word: return .blue
////        case .excel: return .green
////        case .powerpoint: return .orange
////        }
////    }
////}
//
//
//import SwiftUI
//import UniformTypeIdentifiers
//import UIKit
//
//// MARK: - FileType Enum
//enum FileType: String, CaseIterable {
//    case pdf
//    case word
//    case excel
//    case powerpoint
//
//    var fileExtensions: [String] {
//        switch self {
//        case .pdf: return ["pdf"]
//        case .word: return ["doc", "docx"]
//        case .excel: return ["xls", "xlsx"]
//        case .powerpoint: return ["ppt", "pptx"]
//        }
//    }
//
//    var utTypes: [UTType] {
//        switch self {
//        case .pdf:
//            return [.pdf]
//        case .word:
//            return [
//                UTType(filenameExtension: "doc") ?? .data,
//                UTType(filenameExtension: "docx") ?? .data
//            ]
//        case .excel:
//            return [
//                UTType(filenameExtension: "xls") ?? .data,
//                UTType(filenameExtension: "xlsx") ?? .data
//            ]
//        case .powerpoint:
//            return [
//                UTType(filenameExtension: "ppt") ?? .data,
//                UTType(filenameExtension: "pptx") ?? .data
//            ]
//        }
//    }
//
//    var iconName: String {
//        switch self {
//        case .pdf: return "doc.richtext.fill"
//        case .word: return "doc.text.fill"
//        case .excel: return "tablecells.fill"
//        case .powerpoint: return "play.rectangle.fill"
//        }
//    }
//
//    var color: Color {
//        switch self {
//        case .pdf: return .red
//        case .word: return .blue
//        case .excel: return .green
//        case .powerpoint: return .orange
//        }
//    }
//
//    var displayName: String {
//        switch self {
//        case .pdf: return "PDF"
//        case .word: return "Word"
//        case .excel: return "Excel"
//        case .powerpoint: return "PowerPoint"
//        }
//    }
//}
//
//
//// MARK: - Enhanced FileManagerService
//class FileManagerService: NSObject, ObservableObject {
//    static let shared = FileManagerService()
//    private let fileManager = FileManager.default
//    
//    @Published var availableFiles: [URL] = []
//    @Published var isImporting = false
//    @Published var importProgress = 0.0
//    
//    private override init() {
//        super.init()
//        refreshFiles()
//    }
//    
//    // MARK: - Directory Management
//    func getDocumentsDirectory() -> URL {
//        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        return documentsURL
//    }
//    
//    func getInboxDirectory() -> URL {
//        let documentsURL = getDocumentsDirectory()
//        let inboxURL = documentsURL.appendingPathComponent("Inbox")
//        
//        if !fileManager.fileExists(atPath: inboxURL.path) {
//            try? fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: true)
//        }
//        
//        return inboxURL
//    }
//    
//    // MARK: - File Discovery
//    func getAllFiles() -> [URL] {
//        var allFiles: [URL] = []
//        
//        let documentsURL = getDocumentsDirectory()
//        let inboxURL = getInboxDirectory()
//        
//        var searchDirectories = [documentsURL, inboxURL]
//        
//        // App-specific downloads directory
//        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first,
//           fileManager.fileExists(atPath: downloadsURL.path) {
//            searchDirectories.append(downloadsURL)
//        }
//        
//        for directory in searchDirectories {
//            allFiles.append(contentsOf: getFilesFromDirectory(directory))
//        }
//        
//        return allFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
//    }
//    
//    private func getFilesFromDirectory(_ directory: URL) -> [URL] {
//        var files: [URL] = []
//        
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(
//                at: directory,
//                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
//                options: .skipsHiddenFiles
//            )
//            
//            for url in fileURLs {
//                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
//                
//                if resourceValues.isDirectory == true {
//                    files.append(contentsOf: getFilesFromDirectory(url))
//                } else {
//                    let fileExtension = url.pathExtension.lowercased()
//                    if FileType.allCases.flatMap({ $0.fileExtensions }).contains(fileExtension) {
//                        files.append(url)
//                    }
//                }
//            }
//        } catch {
//            print("Error getting files from \(directory): \(error.localizedDescription)")
//        }
//        
//        return files
//    }
//    
//    // MARK: - File Import
//    func importFiles(from urls: [URL]) {
//        isImporting = true
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            let totalFiles = urls.count
//            
//            for (index, url) in urls.enumerated() {
//                _ = self.importFile(from: url)
//                
//                DispatchQueue.main.async {
//                    self.importProgress = Double(index + 1) / Double(totalFiles)
//                }
//            }
//            
//            DispatchQueue.main.async {
//                self.isImporting = false
//                self.importProgress = 0.0
//                self.refreshFiles()
//            }
//        }
//    }
//    
//    private func importFile(from sourceURL: URL) -> URL? {
//        guard sourceURL.startAccessingSecurityScopedResource() else {
//            print("Failed to access security scoped resource")
//            return nil
//        }
//        
//        defer {
//            sourceURL.stopAccessingSecurityScopedResource()
//        }
//        
//        let documentsURL = getDocumentsDirectory()
//        let fileName = sourceURL.lastPathComponent
//        let destinationURL = documentsURL.appendingPathComponent(fileName)
//        let finalDestinationURL = getUniqueFileURL(for: destinationURL)
//        
//        do {
//            try fileManager.copyItem(at: sourceURL, to: finalDestinationURL)
//            return finalDestinationURL
//        } catch {
//            print("Error importing file: \(error.localizedDescription)")
//            return nil
//        }
//    }
//    
//    private func getUniqueFileURL(for url: URL) -> URL {
//        var finalURL = url
//        var counter = 1
//        
//        while fileManager.fileExists(atPath: finalURL.path) {
//            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
//            let fileExtension = url.pathExtension
//            let newName = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
//            finalURL = url.deletingLastPathComponent().appendingPathComponent(newName)
//            counter += 1
//        }
//        
//        return finalURL
//    }
//    
//    // MARK: - File Operations
//    func deleteFile(at url: URL) -> Bool {
//        do {
//            try fileManager.removeItem(at: url)
//            refreshFiles()
//            return true
//        } catch {
//            print("Error deleting file: \(error.localizedDescription)")
//            return false
//        }
//    }
//    
//    func refreshFiles() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            let files = self.getAllFiles()
//            DispatchQueue.main.async {
//                self.availableFiles = files
//            }
//        }
//    }
//    
//    // MARK: - File Information
//    func getFileType(for url: URL) -> FileType {
//        let fileExtension = url.pathExtension.lowercased()
//        for fileType in FileType.allCases {
//            if fileType.fileExtensions.contains(fileExtension) {
//                return fileType
//            }
//        }
//        return .pdf
//    }
//    
//    func getFileSize(for url: URL) -> Int64 {
//        do {
//            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
//            return Int64(resources.fileSize ?? 0)
//        } catch {
//            return 0
//        }
//    }
//    
//    func getModificationDate(for url: URL) -> Date {
//        do {
//            let resources = try url.resourceValues(forKeys: [.contentModificationDateKey])
//            return resources.contentModificationDate ?? Date()
//        } catch {
//            return Date()
//        }
//    }
//    
//    func formatFileSize(_ bytes: Int64) -> String {
//        let formatter = ByteCountFormatter()
//        formatter.allowedUnits = [.useKB, .useMB, .useGB]
//        formatter.countStyle = .file
//        return formatter.string(fromByteCount: bytes)
//    }
//    
//    func isFileAccessible(at url: URL) -> Bool {
//        return fileManager.fileExists(atPath: url.path) && fileManager.isReadableFile(atPath: url.path)
//    }
//}
//
//// MARK: - Document Picker Wrapper
//struct DocumentPicker: UIViewControllerRepresentable {
//    @ObservedObject var fileManager: FileManagerService
//    @Environment(\.presentationMode) var presentationMode
//    
//    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
//        let supportedTypes = FileType.allCases.flatMap { $0.utTypes }
//        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
//        picker.delegate = context.coordinator
//        picker.allowsMultipleSelection = true
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, UIDocumentPickerDelegate {
//        let parent: DocumentPicker
//        
//        init(_ parent: DocumentPicker) {
//            self.parent = parent
//        }
//        
//        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//            parent.fileManager.importFiles(from: urls)
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//        
//        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//    }
//}

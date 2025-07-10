//
//  PersistenceController.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//


import CoreData
import Foundation

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Hanuman_PDF_Reader")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

//// MARK: - Core Data Entities
//
//// FileItem Entity
//@objc(FileItem)
//public class FileItem: NSManagedObject {
//    @NSManaged public var id: UUID
//    @NSManaged public var name: String
//    @NSManaged public var path: String
//    @NSManaged public var fileType: String
//    @NSManaged public var fileSize: Int64
//    @NSManaged public var createdDate: Date
//    @NSManaged public var modifiedDate: Date
//    @NSManaged public var isBookmarked: Bool
//    @NSManaged public var thumbnailData: Data?
//    @NSManaged public var isRecentlyAccessed: Bool
//    @NSManaged public var lastAccessedDate: Date?
//}


extension FileItem{
    var fileTypeEnum: FileType {
        get {/* FileType(rawValue: fileType) ??*/ .pdf }
        set { fileType = newValue.rawValue }
    }
}
//extension FileItem {
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileItem> {
//        return NSFetchRequest<FileItem>(entityName: "FileItem")
//    }
//    
//    var fileTypeEnum: FileType {
//        get { FileType(rawValue: fileType) ?? .pdf }
//        set { fileType = newValue.rawValue }
//    }
//    
//    var formattedFileSize: String {
//        let formatter = ByteCountFormatter()
//        formatter.allowedUnits = [.useKB, .useMB, .useGB]
//        formatter.countStyle = .file
//        return formatter.string(fromByteCount: fileSize)
//    }
//}
//
//// BookmarkModel Entity
//@objc(BookmarkModel)
//public class BookmarkModel: NSManagedObject {
//    @NSManaged public var id: UUID
//    @NSManaged public var fileItem: FileItem
//    @NSManaged public var bookmarkedDate: Date
//    @NSManaged public var notes: String?
//}
//
//extension BookmarkModel {
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookmarkModel> {
//        return NSFetchRequest<BookmarkModel>(entityName: "BookmarkModel")
//    }
//}

// MARK: - Supporting Enums and Structs
//enum FileType: String, CaseIterable {
//    case pdf = "PDF"
//    case word = "WORD"
//    case excel = "EXCEL"
//    case powerpoint = "PPT"
//    
//    var displayName: String {
//        switch self {
//        case .pdf: return "PDF"
//        case .word: return "Word"
//        case .excel: return "Excel"
//        case .powerpoint: return "PowerPoint"
//        }
//    }
//    
//    var fileExtensions: [String] {
//        switch self {
//        case .pdf: return ["pdf"]
//        case .word: return ["doc", "docx"]
//        case .excel: return ["xls", "xlsx"]
//        case .powerpoint: return ["ppt", "pptx"]
//        }
//    }
//}

enum SortType: String, CaseIterable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case dateNewest = "Last Modified (New to Old)"
    case dateOldest = "Last Modified (Old to New)"
    case sizeSmallest = "File Size (Small to Large)"
    case sizeLargest = "File Size (Large to Small)"
}

// MARK: - Core Data Model File (.xcdatamodeld)
// Create a file named PDFReaderPro.xcdatamodeld with the following entities:
/*
Entity: FileItem
Attributes:
- id: UUID
- name: String
- path: String
- fileType: String
- fileSize: Integer 64
- createdDate: Date
- modifiedDate: Date
- isBookmarked: Boolean
- thumbnailData: Binary Data (Optional)
- isRecentlyAccessed: Boolean
- lastAccessedDate: Date (Optional)

Entity: BookmarkModel
Attributes:
- id: UUID
- bookmarkedDate: Date
- notes: String (Optional)

Relationships:
- BookmarkModel.fileItem -> FileItem (To One)
- FileItem.bookmarks -> BookmarkModel (To Many, Delete Rule: Cascade)
*/

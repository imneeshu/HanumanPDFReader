//
//  Hanuman_PDF_ReaderApp.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 05/06/25.
//

import SwiftUI

@main
struct Hanuman_PDF_ReaderApp: App {
    let persistenceController = PersistenceController.shared
    init() {
        // Initialize AdMob
        _ = AdMobManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .accentColor(Color(red: 0.4, green: 0.0, blue: 0.6))
        }
    }
}

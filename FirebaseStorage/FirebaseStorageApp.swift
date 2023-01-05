//
//  FirebaseStorageApp.swift
//  FirebaseStorage
//
//  Created by Elin Simonsson on 2023-01-03.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct FirebaseStorageApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

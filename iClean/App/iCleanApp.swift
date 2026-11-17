//  iCleanApp.swift
//  iClean
//
//  The app's entry point: declares the main scene and roots the window
//  in ContentView, the shared page-switching view.

import SwiftUI

// App entry point; creates a window rooted in the shared page-switching view.
@main
struct iCleanApp: App {
    // Supplies the app's primary window scene.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//
//  BreezeApp.swift
//  Breeze
//
//  Created by Yahil Corcino on 3/15/26.
//

import SwiftUI

@main
struct BreezeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra("Breeze", systemImage: "wind") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

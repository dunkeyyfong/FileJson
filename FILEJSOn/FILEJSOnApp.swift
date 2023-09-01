//
//  FILEJSOnApp.swift
//  FILEJSOn
//
//  Created by DunkeyyFong on 01/09/2023.
//

import SwiftUI
import QuickLook
import UIKit

@main
struct FILEJSOnApp: App {
    
    @StateObject var downloadManager = DownloadManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(downloadManager)
        }
    }
}

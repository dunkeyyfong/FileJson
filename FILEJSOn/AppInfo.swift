//
//  AppInfo.swift
//  FILEJSOn
//
//  Created by DunkeyyFong on 01/09/2023.
//

import Foundation

struct AppInfo: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let developerName: String
    let version: String
    let versionDescription: String
    let downloadURL: String
    let localizedDescription: String
    let iconURL: String?
    let tintColor: String?
    let size: Int?
    let type: Int?
}

struct AppList: Decodable {
    let apps: [AppInfo]
}

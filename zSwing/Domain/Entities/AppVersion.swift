//
//  AppVersion.swift
//  zSwing
//
//  Created by USER on 1/24/25.
//

import Foundation

struct AppVersion {
    let storeVersion: String
    let currentVersion: String
    let updateType: UpdateType
}

enum UpdateType {
    case optional
    case recommended
    case required
}

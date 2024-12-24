//
//  PlaygroundDetail.swift
//  zSwing
//
//  Created by USER on 12/24/24.
//

import Foundation

struct PlaygroundDetail {
    let address: String
    let isFavorite: Bool
    let reviews: [Review]
}

struct PlaygroundWithDistance {
    let playground: Playground
    let distance: Double?
}

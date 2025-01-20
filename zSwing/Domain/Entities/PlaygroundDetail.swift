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
    let playground: Playground1
    let distance: Double?
}

enum PlaygroundFacilityType: String, CaseIterable {
    case swing = "그네"
    case slide = "미끄럼틀"
    case jungleGym = "정글짐"
    case aerial = "공중기구"
    case rotating = "회전기구"
    case rocking = "흔들기구"
    case climbing = "오르는기구"
    case crossing = "건너는기구"
    case composite = "조합놀이대"
    case horizontalBar = "철봉"
    case logBeam = "늑목"
    case balanceBeam = "평균대"
    
    var imageName: String {
        switch self {
        case .swing: return "arrow.up.and.down"
        case .slide: return "arrow.down.forward.circle.fill"
        case .jungleGym: return "cube.transparent"
        case .aerial: return "airplane"
        case .rotating: return "rotate.3d"
        case .rocking: return "wave.3.right"
        case .climbing: return "arrow.up.circle"
        case .crossing: return "arrow.left.and.right"
        case .composite: return "square.stack.3d.up"
        case .horizontalBar: return "figure.gymnastics"
        case .logBeam: return "arrow.up.and.down.square"
        case .balanceBeam: return "minus"
        }
    }
}

struct PlaygroundFacility {
    let type: PlaygroundFacilityType
    
    var name: String { type.rawValue }
    var imageName: String { type.imageName }
}

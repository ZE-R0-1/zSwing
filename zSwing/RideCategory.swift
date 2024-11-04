//
//  RideCategory.swift
//  zSwing
//
//  Created by USER on 11/4/24.
//

import Foundation

enum RideCategory: String, CaseIterable {
    case swing = "D001"
    case slide = "D002"
    case jungle = "D003"
    case aerial = "D004"
    case rotating = "D005"
    case rocking = "D006"
    case climbing = "D007"
    case crossing = "D008"
    case combination = "D009"
    case horizontalBar = "D020"
    case log = "D021"
    case balanceBeam = "D022"
    case other = "D080"
    case surfaceSand = "D091"
    case surfaceRubber = "D092"
    case surfaceCoating = "D093"
    case surfaceOther = "D094"
    
    var displayName: String {
        switch self {
        case .swing: return "그네"
        case .slide: return "미끄럼틀"
        case .jungle: return "정글짐"
        case .aerial: return "공중놀이기구"
        case .rotating: return "회전놀이기구"
        case .rocking: return "흔들놀이기구"
        case .climbing: return "오르는기구"
        case .crossing: return "건너는기구"
        case .combination: return "조합놀이대"
        case .horizontalBar: return "철봉"
        case .log: return "늑목"
        case .balanceBeam: return "평균대"
        case .other: return "기타"
        case .surfaceSand: return "충격흡수용표면재(모래)"
        case .surfaceRubber: return "충격흡수용표면재(고무바닥재)"
        case .surfaceCoating: return "충격흡수용표면재(포설도포바닥재)"
        case .surfaceOther: return "충격흡수용표면재(기타바닥재)"
        }
    }
}

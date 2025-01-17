//
//  PlaygroundDTO.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import Foundation
import CoreLocation

struct PlaygroundDTO {
    let pfctSn: String      // 놀이시설일련번호
    let pfctNm: String      // 놀이시설명
    let latCrtsVl: Double   // 위도
    let lotCrtsVl: Double   // 경도
    let idrodrCdNm: String  // 실내/실외 구분
}

// 필터링을 위한 PlaygroundType
enum PlaygroundType: String {
    case all = "전체"
    case indoor = "실내"
    case outdoor = "실외"
    
    static var allTypes: [PlaygroundType] {
        return [.all, .indoor, .outdoor]
    }
    
    var segmentIndex: Int {
        switch self {
        case .all: return 0
        case .indoor: return 1
        case .outdoor: return 2
        }
    }
    
    static func fromSegmentIndex(_ index: Int) -> PlaygroundType {
        switch index {
        case 1: return .indoor
        case 2: return .outdoor
        default: return .all
        }
    }
}

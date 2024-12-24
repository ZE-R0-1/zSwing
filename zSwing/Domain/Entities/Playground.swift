//
//  Playground.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import Foundation
import CoreLocation

struct Playground {
    let pfctSn: String       // 놀이시설일련번호
    let pfctNm: String       // 놀이시설명
    let coordinate: CLLocationCoordinate2D
    let idrodrCdNm: String   // 실내/실외 구분
    var rides: [Ride] = []   // 놀이기구 정보
    var reviews: [Review] = [] // 리뷰 정보
    
    // 편의를 위한 계산 프로퍼티
    var isIndoor: Bool {
        return idrodrCdNm == "실내"
    }
}

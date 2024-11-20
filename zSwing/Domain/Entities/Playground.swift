//
//  Playground.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import Foundation
import CoreLocation

struct Playground {
    let pfctSn: String
    let pfctNm: String
    let coordinate: CLLocationCoordinate2D
    var rides: [Ride] = []  // 놀이기구 정보 추가
}

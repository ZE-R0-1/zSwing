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
    
    // 카테고리별 놀이기구 수를 계산하는 메서드
    func getCategoryCounts() -> [CategoryCount] {
        var countDict: [String: Int] = [:]
        
        // 각 놀이기구의 카테고리별 수량 집계
        rides.forEach { ride in
            countDict[ride.category, default: 0] += 1
        }
        
        // CategoryCount 배열로 변환
        return countDict.map { CategoryCount(name: $0.key, count: $0.value) }
    }
    
    // 특정 카테고리들을 포함하고 있는지 확인하는 메서드
    func hasCategories(_ categories: Set<String>) -> Bool {
        guard !categories.isEmpty else { return true }
        let playgroundCategories = Set(rides.map { $0.category })
        return !categories.isDisjoint(with: playgroundCategories)
    }
    
    // 현재 위치로부터의 거리
    func distance(from location: CLLocation) -> CLLocationDistance {
        let playgroundLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: playgroundLocation)
    }
}

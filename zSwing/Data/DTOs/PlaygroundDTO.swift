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
    
    func toDomain() -> Playground {
        return Playground(
            pfctSn: pfctSn,
            pfctNm: pfctNm,
            coordinate: CLLocationCoordinate2D(
                latitude: latCrtsVl,
                longitude: lotCrtsVl
            )
        )
    }
}

//
//  RideInfo.swift
//  zSwing
//
//  Created by USER on 10/29/24.
//

import Foundation

struct RideInfo: Equatable {
    let rideSn: String
    let installDate: String
    let facilityName: String
    let rideName: String
    let rideType: RideCategory
    let address: String
}

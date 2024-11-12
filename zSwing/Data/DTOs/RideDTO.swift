//
//  RideDTO.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//


import Foundation
import FirebaseFirestore
import CoreLocation

struct RideDTO: Codable {
    let rideSn: String
    let pfctSn: String
    let installDate: String
    let facilityName: String
    let rideName: String
    let rideType: String
    let address: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case rideSn = "rideSn"
        case pfctSn = "pfctSn"
        case installDate = "rideInstlYmd"
        case facilityName = "pfctNm"
        case rideName = "rideNm"
        case rideType = "rideStylCd"
        case address = "ronaAddr"
        case latitude = "latCrtsVl"
        case longitude = "lotCrtsVl"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        rideSn = try container.decode(String.self, forKey: .rideSn)
        pfctSn = try container.decode(String.self, forKey: .pfctSn)
        installDate = try container.decode(String.self, forKey: .installDate)
        facilityName = try container.decode(String.self, forKey: .facilityName)
        rideName = try container.decode(String.self, forKey: .rideName)
        rideType = try container.decode(String.self, forKey: .rideType)
        address = try container.decode(String.self, forKey: .address)
        
        // Firebase에서는 String으로 저장되어 있으므로 Double로 변환
        if let latString = try? container.decode(String.self, forKey: .latitude),
           let lat = Double(latString) {
            latitude = lat
        } else {
            latitude = try container.decode(Double.self, forKey: .latitude)
        }
        
        if let lonString = try? container.decode(String.self, forKey: .longitude),
           let lon = Double(lonString) {
            longitude = lon
        } else {
            longitude = try container.decode(Double.self, forKey: .longitude)
        }
    }
    
    func toDomain() -> MapItem {
        return MapItem(
            id: rideSn,
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            rideInfo: RideInfo(
                rideSn: rideSn,
                installDate: installDate,
                facilityName: facilityName,
                rideName: rideName,
                rideType: RideCategory(rawValue: rideType) ?? .other,
                address: address
            ),
            distance: nil
        )
    }
}

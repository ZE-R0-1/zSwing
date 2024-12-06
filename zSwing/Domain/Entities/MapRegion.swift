//
//  MapRegion.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import Foundation
import CoreLocation
import MapKit

struct MapRegion {
   let center: CLLocationCoordinate2D
   let span: MKCoordinateSpan
   
   static var defaultRegion: MapRegion {
       return MapRegion(
           center: CLLocationCoordinate2D(
               latitude: 37.5665, // 서울 시청 좌표
               longitude: 126.9780
           ),
           span: MKCoordinateSpan(
               latitudeDelta: 0.1,
               longitudeDelta: 0.1
           )
       )
   }
}

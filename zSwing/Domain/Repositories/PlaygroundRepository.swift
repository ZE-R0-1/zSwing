//
//  PlaygroundRepository.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import RxSwift
import CoreLocation

protocol PlaygroundRepository {
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground1]>
    func fetchFilteredPlaygrounds(categories: Set<String>, in region: MapRegion) -> Observable<[Playground1]>
}

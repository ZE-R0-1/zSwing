//
//  RideCategoryViewModel.swift
//  zSwing
//
//  Created by USER on 1/19/25.
//

import RxSwift
import RxRelay
import CoreLocation

class RideCategoryViewModel {
    // MARK: - Properties
    
    // Input
    private let facility: PlaygroundFacility
    let locationManager: LocationManager
    
    // Output
    let categories = BehaviorRelay<[String]>(value: PlaygroundFacilityType.allCases.map { $0.rawValue })
    let selectedIndex: BehaviorRelay<Int>
    let isMapMode = BehaviorRelay<Bool>(value: false)
    
    let playgrounds = BehaviorRelay<[Playground]>(value: [])
    lazy var filteredPlaygrounds: Observable<[Playground]> = Observable.combineLatest(
        selectedIndex,
        playgrounds,
        sortOption
    ).map { [weak self] index, playgrounds, sort in
        guard let self = self else { return [] }
        
        let selectedFacilityType = PlaygroundFacilityType.allCases[index]
        let filtered = playgrounds.filter { playground in
            playground.facilities.contains { facility in
                facility.type == selectedFacilityType
            }
        }
        
        return self.sortPlaygrounds(filtered, by: sort)
    }
    
    let sortOption = BehaviorRelay<SortOption>(value: .distance)
    
    // MARK: - Types
    
    enum SortOption {
        case distance
        case madeAt
        case facilityCount
    }
    
    // MARK: - Initialization
    
    init(facility: PlaygroundFacility, locationManager: LocationManager) {
        self.facility = facility
        self.locationManager = locationManager
        
        let index = PlaygroundFacilityType.allCases.firstIndex { $0.rawValue == facility.name } ?? 0
        self.selectedIndex = BehaviorRelay<Int>(value: index)
        
        // 샘플 데이터 추가
        let samplePlaygrounds: [Playground] = [
            Playground(
                id: "1",
                name: "어린이대공원 놀이터",
                address: "서울시 광진구 능동로 216",
                coordinate: CLLocationCoordinate2D(latitude: 37.5478, longitude: 127.0830),
                facilities: [
                    PlaygroundFacility(type: .swing),
                    PlaygroundFacility(type: .slide),
                    PlaygroundFacility(type: .climbing)
                ],
                madeAt: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
            ),
            Playground(
                id: "2",
                name: "뚝섬한강공원 놀이터",
                address: "서울시 성동구 자동차시장길 49",
                coordinate: CLLocationCoordinate2D(latitude: 37.5297, longitude: 127.0668),
                facilities: [
                    PlaygroundFacility(type: .swing),
                    PlaygroundFacility(type: .slide),
                    PlaygroundFacility(type: .composite)
                ],
                madeAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            ),
            Playground(
                id: "3",
                name: "서울숲 놀이터",
                address: "서울시 성동구 뚝섬로 273",
                coordinate: CLLocationCoordinate2D(latitude: 37.5445, longitude: 127.0374),
                facilities: [
                    PlaygroundFacility(type: .swing),
                    PlaygroundFacility(type: .jungleGym),
                    PlaygroundFacility(type: .composite),
                    PlaygroundFacility(type: .climbing)
                ],
                madeAt: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            )
        ]
        
        // 샘플 데이터로 playgrounds 초기화
        playgrounds.accept(samplePlaygrounds)
        
        // filteredPlaygrounds Observable 설정
        self.filteredPlaygrounds = Observable.combineLatest(
            selectedIndex,
            playgrounds,
            sortOption
        ).map { [weak self] index, playgrounds, sort in
            guard let self = self else { return [] }
            
            let selectedFacilityType = PlaygroundFacilityType.allCases[index]
            let filtered = playgrounds.filter { playground in
                playground.facilities.contains { facility in
                    facility.type == selectedFacilityType
                }
            }
            
            return self.sortPlaygrounds(filtered, by: sort)
        }
        
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Public Methods
    
    func toggleViewMode() {
        isMapMode.accept(!isMapMode.value)
    }
    
    func categorySelected(at index: Int) {
        selectedIndex.accept(index)
    }
    
    func updateSortOption(_ option: SortOption) {
        sortOption.accept(option)
    }
    
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let currentLocation = locationManager.currentLocation else {
            return .greatestFiniteMagnitude
        }
        
        let playgroundLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: playgroundLocation)
    }
    
    // MARK: - Private Methods
    
    private func sortPlaygrounds(_ playgrounds: [Playground], by option: SortOption) -> [Playground] {
        switch option {
        case .distance:
            return playgrounds.sorted { playground1, playground2 in
                let distance1 = self.calculateDistance(to: playground1.coordinate)
                let distance2 = self.calculateDistance(to: playground2.coordinate)
                return distance1 < distance2
            }
            
        case .madeAt:
            return playgrounds.sorted { $0.madeAt > $1.madeAt }
            
        case .facilityCount:
            return playgrounds.sorted { $0.facilities.count > $1.facilities.count }
        }
    }
}

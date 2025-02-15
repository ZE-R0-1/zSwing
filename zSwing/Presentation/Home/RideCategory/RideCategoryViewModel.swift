//
//  RideCategoryViewModel.swift
//  zSwing
//
//  Created by USER on 1/19/25.
//

import RxSwift
import RxRelay
import CoreLocation
import MapKit

class RideCategoryViewModel {
    // MARK: - Properties
    
    // Input
    private let facility: PlaygroundFacility
    let locationManager: LocationManager
    
    // Output
    let categories = BehaviorRelay<[String]>(value: ["전체"] + PlaygroundFacilityType.allCases.map { $0.rawValue })
    let selectedIndex: BehaviorRelay<Int>
    let isMapMode = BehaviorRelay<Bool>(value: false)
    let playgrounds = BehaviorRelay<[Playground]>(value: [])
    let sortOption = BehaviorRelay<SortOption>(value: .distance)
    
    let visibleRegion = BehaviorRelay<MKCoordinateRegion?>(value: nil)
    
    lazy var filteredPlaygrounds: Observable<[Playground]> = {
        return Observable.combineLatest(
            selectedIndex,
            playgrounds,
            sortOption,
            locationManager.currentLocationObservable.compactMap { $0 },
            visibleRegion.asObservable()
        ).map { [weak self] index, playgrounds, sort, location, region in
            guard let self = self else { return [] }
            
            let selectedFacilityType = PlaygroundFacilityType.allCases[index]
            var filtered = playgrounds
            if index > 0 { // "전체"가 아닌 경우에만 필터링
                let selectedFacilityType = PlaygroundFacilityType.allCases[index - 1]
                filtered = playgrounds.filter { playground in
                    playground.facilities.contains { facility in
                        facility.type == selectedFacilityType
                    }
                }
            }
            
            // 지도에 보이는 영역으로 필터링 (모드와 관계없이)
            if let region = region {
                filtered = filtered.filter { playground in
                    let coordinate = playground.coordinate
                    let latitudeDelta = region.span.latitudeDelta / 2
                    let longitudeDelta = region.span.longitudeDelta / 2
                    
                    let minLat = region.center.latitude - latitudeDelta
                    let maxLat = region.center.latitude + latitudeDelta
                    let minLon = region.center.longitude - longitudeDelta
                    let maxLon = region.center.longitude + longitudeDelta
                    
                    return coordinate.latitude >= minLat &&
                           coordinate.latitude <= maxLat &&
                           coordinate.longitude >= minLon &&
                           coordinate.longitude <= maxLon
                }
            }
            
            switch sort {
            case .distance:
                return filtered.sorted { playground1, playground2 in
                    let location1 = CLLocation(latitude: playground1.coordinate.latitude, longitude: playground1.coordinate.longitude)
                    let location2 = CLLocation(latitude: playground2.coordinate.latitude, longitude: playground2.coordinate.longitude)
                    return location.distance(from: location1) < location.distance(from: location2)
                }
                
            case .madeAt:
                return filtered.sorted { $0.madeAt > $1.madeAt }
                
            case .facilityCount:
                return filtered.sorted { $0.facilities.count > $1.facilities.count }
            }
        }
    }()
    
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
        
        let index = facility.name == "전체" ? 0 : (PlaygroundFacilityType.allCases.firstIndex { $0.rawValue == facility.name }.map { $0 + 1 } ?? 0)
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
            ),
            Playground(
                id: "4",
                name: "서울숲 놀이터2",
                address: "서울시 성동구 뚝섬로 273",
                coordinate: CLLocationCoordinate2D(latitude: 37.5445, longitude: 127.0374),
                facilities: [
                    PlaygroundFacility(type: .swing),
                    PlaygroundFacility(type: .jungleGym),
                    PlaygroundFacility(type: .composite),
                    PlaygroundFacility(type: .climbing)
                ],
                madeAt: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            ),
            Playground(
                id: "5",
                name: "뚝섬한강공원 놀이터2",
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
                id: "6",
                name: "뚝섬한강공원 놀이터3",
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
                id: "7",
                name: "뚝섬한강공원 놀이터4",
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
                id: "8",
                name: "신림 놀이터",
                address: "서울시 관악구",
                coordinate: CLLocationCoordinate2D(latitude: 37.4864, longitude: 126.9294),
                facilities: [
                    PlaygroundFacility(type: .swing),
                    PlaygroundFacility(type: .slide),
                    PlaygroundFacility(type: .composite)
                ],
                madeAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            ),
            Playground(
                id: "9",
                name: "신림 놀이터2",
                address: "서울시 관악구",
                coordinate: CLLocationCoordinate2D(latitude: 37.4864, longitude: 126.9264),
                facilities: [
                    PlaygroundFacility(type: .swing),
                    PlaygroundFacility(type: .slide),
                    PlaygroundFacility(type: .composite)
                ],
                madeAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            )
        ]
        
        // 샘플 데이터로 playgrounds 초기화
        playgrounds.accept(samplePlaygrounds)
        
        // 위치 업데이트 시작
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
    
    // 지도 영역 업데이트 메서드
    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleRegion.accept(region)
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

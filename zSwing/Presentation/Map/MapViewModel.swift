//
//  MapViewModel.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import RxSwift
import RxRelay
import MapKit
import CoreLocation

import RxSwift
import RxRelay
import MapKit
import CoreLocation

class MapViewModel {
    // MARK: - Properties
    private let useCase: MapUseCase
    private let disposeBag = DisposeBag()
    let playgroundListViewModel: PlaygroundListViewModel
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let searchButtonTapped = PublishRelay<MapRegion>()
    let mapRegionDidChange = PublishRelay<MKCoordinateRegion>()
    let initialRegion = PublishRelay<MKCoordinateRegion>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<Location>(value: .defaultLocation)
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let shouldShowSearchButton = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initialization
    init(useCase: MapUseCase, playgroundListViewModel: PlaygroundListViewModel) {
        self.useCase = useCase
        self.playgroundListViewModel = playgroundListViewModel
        setupBindings()
    }
    
    private func setupBindings() {
        // 초기 진입 시 한 번만 실행
        viewDidLoad
            .take(1)
            .withLatestFrom(initialRegion)
            .do(onNext: { [weak self] region in
                self?.isLoading.accept(true)
                let mapRegion = MapRegion(
                    center: region.center,
                    span: region.span
                )
                self?.playgroundListViewModel.searchButtonTapped.accept(mapRegion)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Bool, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.requestLocationPermission()
            }
            .flatMapLatest { [weak self] result -> Observable<Result<Location, Error>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success(true):
                    return self.useCase.getCurrentLocation()
                case .success(false):
                    return .just(.success(.defaultLocation))
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            .do(onNext: { [weak self] result in
                if case .success(let location) = result {
                    self?.currentLocation.accept(location)
                }
                self?.isLoading.accept(false)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 현재 위치 버튼 탭 처리
        locationButtonTapped
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Location, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.getCurrentLocation()
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] result in
                if case .success(let location) = result {
                    self?.currentLocation.accept(location)
                }
            })
            .disposed(by: disposeBag)
        
        // 지도 이동 시 검색 버튼 표시/숨김 처리
        mapRegionDidChange
            .skip(1)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged { old, new in
                // 중요한 변화가 있을 때만 처리
                let latDiff = abs(old.center.latitude - new.center.latitude)
                let lonDiff = abs(old.center.longitude - new.center.longitude)
                let spanLatDiff = abs(old.span.latitudeDelta - new.span.latitudeDelta)
                let spanLonDiff = abs(old.span.longitudeDelta - new.span.longitudeDelta)
                
                return latDiff < 0.01 && lonDiff < 0.01 &&
                spanLatDiff < 0.01 && spanLonDiff < 0.01
            }
            .map { _ in true }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭 처리
        searchButtonTapped
            .subscribe(onNext: { [weak self] region in
                self?.playgroundListViewModel.searchButtonTapped.accept(region)
            })
            .disposed(by: disposeBag)
    }
}

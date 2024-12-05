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

class MapViewModel {
    // MARK: - Properties
    private let useCase: MapUseCase
    private let disposeBag = DisposeBag()
    private let playgroundListViewModel: PlaygroundListViewModel
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let regionDidChange = PublishRelay<MKCoordinateRegion>()
    let searchButtonTapped = PublishRelay<Void>()
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
        // 초기 진입 시
        viewDidLoad
            .withLatestFrom(initialRegion)
            .do(onNext: { [weak self] region in
                self?.isLoading.accept(true)
                let mapRegion = MapRegion(
                    center: region.center,
                    span: region.span
                )
                self?.playgroundListViewModel.regionChanged.accept(mapRegion)
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
                    self?.searchButtonTapped.accept(())
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
        
        // 검색 버튼 탭 처리
        searchButtonTapped
            .withLatestFrom(regionDidChange)
            .do(onNext: { [weak self] region in
                self?.isLoading.accept(true)
                self?.shouldShowSearchButton.accept(false)
                self?.updateLocationTitle(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )
                let mapRegion = MapRegion(
                    center: region.center,
                    span: region.span
                )
                self?.playgroundListViewModel.regionChanged.accept(mapRegion)
            })
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 지도 이동 시 검색 버튼 표시/숨김 처리
        regionDidChange
            .skip(1)
            .withLatestFrom(isLoading) { (region, isLoading) in
                return !isLoading
            }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
    }
    
    private func updateLocationTitle(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                self?.error.accept(error)
                return
            }
        }
    }
}

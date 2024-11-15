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
    private let playgroundUseCase: PlaygroundUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let regionDidChange = PublishRelay<MKCoordinateRegion>()
    let searchButtonTapped = PublishRelay<Void>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<MapLocation>(value: .defaultLocation)
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let playgrounds = BehaviorRelay<[Playground]>(value: [])
    let shouldShowSearchButton = BehaviorRelay<Bool>(value: false)
    let shouldShowBottomSheet = BehaviorRelay<Bool>(value: true)
    
    init(useCase: MapUseCase, playgroundUseCase: PlaygroundUseCase) {
        self.useCase = useCase
        self.playgroundUseCase = playgroundUseCase
        setupBindings()
    }
    
    private func setupBindings() {
        // 초기 위치 설정 및 데이터 로드
        viewDidLoad
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Bool, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.requestLocationPermission()
            }
            .flatMapLatest { [weak self] result -> Observable<Result<MapLocation, Error>> in
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
            })
            .flatMapLatest { [weak self] result -> Observable<[Playground]> in
                guard let self = self,
                      case .success(let location) = result else { return .empty() }
                
                return self.playgroundUseCase.fetchPlaygroundsNearby(
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                )
                .catch { error -> Observable<[Playground]> in
                    self.error.accept(error)
                    return .just([])
                }
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
                self?.shouldShowBottomSheet.accept(true)
            })
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
        
        // 위치 버튼 탭 - 현재 위치로 이동
        locationButtonTapped
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<MapLocation, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.getCurrentLocation()
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let location):
                    self?.currentLocation.accept(location)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // 지도 영역 변경시 검색 버튼 표시
        regionDidChange
            .skip(2)  // 초기 로딩 스킵
            .withLatestFrom(isLoading) { (region, isLoading) in
                return !isLoading
            }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭
        searchButtonTapped
            .withLatestFrom(regionDidChange)
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
                self?.shouldShowSearchButton.accept(false)
            })
            .flatMapLatest { [weak self] region -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
                return self.playgroundUseCase.fetchPlaygrounds(in: MapRegion(
                    center: region.center,
                    span: region.span
                ))
                .catch { error -> Observable<[Playground]> in
                    self.error.accept(error)
                    return .just([])
                }
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
                self?.shouldShowBottomSheet.accept(true)
            })
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
    }
}

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
        // 위치 권한 및 초기 위치 설정
        viewDidLoad
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
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let location):
                    self?.currentLocation.accept(location)
                    self?.loadPlaygrounds(near: location)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // 위치 버튼 탭
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
                    self?.loadPlaygrounds(near: location)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // 지도 영역 변경
        regionDidChange
            .skip(1)  // 초기 로딩 스킵
            .map { _ in true }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭
        searchButtonTapped
            .withLatestFrom(regionDidChange)
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
                // 로딩 시작할 때 바텀시트 숨기기
                self?.shouldShowBottomSheet.accept(false)
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
            .do(onNext: { [weak self] playgrounds in
                self?.isLoading.accept(false)
                // 데이터가 있을 때만 바텀시트 표시
                self?.shouldShowBottomSheet.accept(!playgrounds.isEmpty)
            })
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func loadPlaygrounds(near location: MapLocation) {
        isLoading.accept(true)
        shouldShowBottomSheet.accept(false) // 로딩 시작할 때 바텀시트 숨기기
        
        playgroundUseCase.fetchPlaygroundsNearby(
            coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
        )
        .catch { error -> Observable<[Playground]> in
            self.error.accept(error)
            return .just([])
        }
        .do(onNext: { [weak self] playgrounds in
            self?.isLoading.accept(false)
            // 데이터가 있을 때만 바텀시트 표시
            self?.shouldShowBottomSheet.accept(!playgrounds.isEmpty)
        })
        .bind(to: playgrounds)
        .disposed(by: disposeBag)
    }
}

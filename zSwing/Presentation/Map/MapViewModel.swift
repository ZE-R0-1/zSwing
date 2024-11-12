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
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let mapRegionDidChange = PublishRelay<MKCoordinateRegion>()
    let bottomSheetStateDidChange = PublishRelay<CGFloat>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<MapLocation>(value: .defaultLocation)
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let shouldUpdateBottomSheet = PublishRelay<Bool>()
    let mapInteractionEnabled = BehaviorRelay<Bool>(value: true)
    
    init(useCase: MapUseCase) {
        self.useCase = useCase
        setupBindings()
    }
    
    private func setupBindings() {
        // 초기 위치 권한 요청 및 위치 가져오기
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
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // 위치 버튼 탭 처리
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
        
        // 지도 영역 변경에 따른 바텀시트 업데이트
        mapRegionDidChange
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] region in
                self?.updateBottomSheetContent(for: region)
            })
            .disposed(by: disposeBag)
        
        // 바텀시트 상태에 따른 맵 인터랙션 제어
        bottomSheetStateDidChange
            .map { percentage -> Bool in
                return percentage < 0.5
            }
            .bind(to: mapInteractionEnabled)
            .disposed(by: disposeBag)
    }
    
    private func updateBottomSheetContent(for region: MKCoordinateRegion) {
        // 현재 지도 영역에 따른 바텀시트 컨텐츠 업데이트 로직
        shouldUpdateBottomSheet.accept(true)
    }
}

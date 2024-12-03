//
//  ProfileViewModel.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import RxSwift
import RxRelay
import Foundation

class ProfileViewModel {
    // MARK: - Properties
    private let useCase: ProfileUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let logoutTapped = PublishRelay<Void>()
    let withdrawTapped = PublishRelay<Void>()
    let withdrawConfirmed = PublishRelay<Void>()
    
    // MARK: - Outputs
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let currentUser = BehaviorRelay<User?>(value: nil)
    let navigationRequest = PublishRelay<ProfileNavigationRequest>()
    
    enum ProfileNavigationRequest {
        case logout
        case withdraw
        case showWithdrawConfirmation
    }
    
    init(useCase: ProfileUseCase) {
        self.useCase = useCase
        setupBindings()
    }
    
    private func setupBindings() {
        // Handle logout
        logoutTapped
            .do(onNext: { [weak self] in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Void, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.logout()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoading.accept(false)
                switch result {
                case .success:
                    self?.navigationRequest.accept(.logout)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // Show withdraw confirmation
        withdrawTapped
            .map { ProfileNavigationRequest.showWithdrawConfirmation }
            .bind(to: navigationRequest)
            .disposed(by: disposeBag)
        
        // Handle withdraw
        withdrawConfirmed
            .do(onNext: { [weak self] in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Void, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.withdraw()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoading.accept(false)
                switch result {
                case .success:
                    self?.navigationRequest.accept(.withdraw)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
    }
}

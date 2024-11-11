//
//  ProfileViewModel.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import RxSwift
import RxRelay

class ProfileViewModel {
    // MARK: - Dependencies
    private let useCase: ProfileUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let logoutTapped = PublishRelay<Void>()
    let withdrawTapped = PublishRelay<Void>()
    let withdrawConfirmed = PublishRelay<Void>()
    
    // MARK: - Outputs
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let navigationEvent = PublishRelay<ProfileNavigationEvent>()
    let showConfirmation = PublishRelay<String>()
    let currentUser = BehaviorRelay<User?>(value: nil)
    
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
                    self?.navigationEvent.accept(.login)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // Handle withdraw button tap to show confirmation
        withdrawTapped
            .map { "정말로 탈퇴하시겠습니까?\n이 작업은 되돌릴 수 없으며 모든 데이터가 삭제됩니다." }
            .bind(to: showConfirmation)
            .disposed(by: disposeBag)
        
        // Handle withdraw confirmation
        withdrawConfirmed
            .do(onNext: { [weak self] in
                self?.isLoading.accept(true)
                print("Withdrawal started")
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
                    print("Withdrawal successful, navigating to login")
                    self?.navigationEvent.accept(.login)
                case .failure(let error):
                    print("Withdrawal failed: \(error)")
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
        
        // Fetch current user on initialization
        useCase.getCurrentUser()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let user):
                    self?.currentUser.accept(user)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
    }
}

enum ProfileNavigationEvent {
    case login
}

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
                    .do(onNext: { result in
                        switch result {
                        case .success:
                            // 로그아웃 성공 시 UserDefaults에서 닉네임 상태 제거
                            UserDefaults.standard.removeObject(forKey: "hasNickname")
                        case .failure:
                            break
                        }
                    })
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoading.accept(false)
                switch result {
                case .success:
                    self?.navigationEvent.accept(.loginWithoutNickname) // 닉네임 입력 없이 로그인 화면으로
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
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Void, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.withdraw()
                    .do(onNext: { result in
                        switch result {
                        case .success:
                            // 회원탈퇴 성공 시 UserDefaults에서 닉네임 상태 제거
                            UserDefaults.standard.removeObject(forKey: "hasNickname")
                        case .failure:
                            break
                        }
                    })
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoading.accept(false)
                switch result {
                case .success:
                    self?.navigationEvent.accept(.loginWithNickname) // 회원가입처럼 닉네임 입력 필요
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
    }
}

enum ProfileNavigationEvent {
    case loginWithNickname     // 회원탈퇴 후 - 닉네임 입력 필요
    case loginWithoutNickname  // 로그아웃 후 - 닉네임 입력 불필요
}

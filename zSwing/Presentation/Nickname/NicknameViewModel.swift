//
//  NicknameViewModel.swift
//  zSwing
//
//  Created by USER on 11/11/24.
//

import RxSwift
import RxRelay

class NicknameViewModel {
    // MARK: - Properties
    private let useCase: NicknameUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let nicknameTrigger = PublishRelay<String>()
    
    // MARK: - Outputs
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let nicknameValid = BehaviorRelay<Bool>(value: false)
    let navigationEvent = PublishRelay<NicknameNavigationEvent>()
    
    init(useCase: NicknameUseCase) {
        self.useCase = useCase
        setupBindings()
        checkExistingNickname()
    }
    
    private func setupBindings() {
        nicknameTrigger
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] nickname -> Observable<Result<Void, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.saveNickname(nickname)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoading.accept(false)
                switch result {
                case .success:
                    self?.navigationEvent.accept(.mainScreen)
                case .failure(let error):
                    self?.error.accept(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func checkExistingNickname() {
        useCase.checkNicknameExists()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] exists in
                if exists {
                    self?.navigationEvent.accept(.mainScreen)
                }
            })
            .disposed(by: disposeBag)
    }
}

enum NicknameNavigationEvent {
    case mainScreen
}

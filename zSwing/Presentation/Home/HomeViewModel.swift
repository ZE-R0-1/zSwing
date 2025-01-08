//
//  HomeViewModel.swift
//  zSwing
//
//  Created by USER on 1/8/25.
//

import RxSwift
import RxRelay

class HomeViewModel {
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    
    // MARK: - Outputs
//    let posts = BehaviorRelay<[Post]>(value: [])  // Post 모델은 나중에 정의
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // 추후 데이터 바인딩 로직 추가
    }
}

//
//  HomeViewModel.swift
//  zSwing
//
//  Created by USER on 1/8/25.
//

import RxSwift
import RxRelay
import Foundation
import FirebaseFirestore

class HomeViewModel {
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let refreshTrigger = PublishRelay<Void>()
    let loadMoreTrigger = PublishRelay<Void>()
    let likeTrigger = PublishRelay<String>()  // postId
    
    // MARK: - Outputs
    let posts = BehaviorRelay<[Post]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    
    // MARK: - Properties
    private let useCase: PostUseCase
    private let disposeBag = DisposeBag()
    private var currentPage = 0
    private var isLastPage = false
    
    // MARK: - Initialization
    init(useCase: PostUseCase) {
        self.useCase = useCase
        setupBindings()
    }
    
    private func setupBindings() {
        // 초기 로딩
        let initialLoad = viewDidLoad
            .do(onNext: { [weak self] in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<[Post]> in
                guard let self = self else { return .empty() }
                self.currentPage = 0
                return self.useCase.fetchPosts(page: self.currentPage)
            }
        
        // 새로고침
        let refresh = refreshTrigger
            .do(onNext: { [weak self] in
                self?.currentPage = 0
                self?.isLastPage = false
            })
            .flatMapLatest { [weak self] _ -> Observable<[Post]> in
                guard let self = self else { return .empty() }
                return self.useCase.fetchPosts(page: self.currentPage)
            }
        
        // 추가 로딩
        let loadMore = loadMoreTrigger
            .filter { [weak self] _ in
                guard let self = self else { return false }
                return !self.isLoading.value && !self.isLastPage
            }
            .do(onNext: { [weak self] in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<[Post]> in
                guard let self = self else { return .empty() }
                self.currentPage += 1
                return self.useCase.fetchPosts(page: self.currentPage)
            }
        
        // 좋아요 토글
        likeTrigger
            .flatMapLatest { [weak self] postId -> Observable<(String, Bool)> in
                guard let self = self else { return .empty() }
                return self.useCase.toggleLike(postId: postId)
                    .map { (postId, $0) }
            }
            .subscribe(onNext: { [weak self] postId, isLiked in
                guard let self = self else { return }
                var currentPosts = self.posts.value
                if let index = currentPosts.firstIndex(where: { $0.id == postId }) {
                    var updatedPost = currentPosts[index]
                    updatedPost.isLiked = isLiked
                    updatedPost.likeCount += isLiked ? 1 : -1
                    currentPosts[index] = updatedPost
                    self.posts.accept(currentPosts)
                }
            })
            .disposed(by: disposeBag)
        
        // 데이터 처리
        Observable.merge(initialLoad, refresh, loadMore)
            .do(onNext: { [weak self] posts in
                self?.isLastPage = posts.isEmpty
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] newPosts in
                guard let self = self else { return }
                if self.currentPage == 0 {
                    self.posts.accept(newPosts)
                } else {
                    let currentPosts = self.posts.value
                    self.posts.accept(currentPosts + newPosts)
                }
            }, onError: { [weak self] error in
                self?.error.accept(error)
                self?.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
}

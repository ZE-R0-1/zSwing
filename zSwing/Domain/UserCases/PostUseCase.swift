//
//  PostUseCase.swift
//  zSwing
//
//  Created by USER on 1/10/25.
//

import RxSwift

protocol PostUseCase {
    func fetchPosts(page: Int) -> Observable<[Post]>
    func toggleLike(postId: String) -> Observable<Bool>
}

final class DefaultPostUseCase: PostUseCase {
    private let repository: PostRepository
    private let pageSize: Int = 20
    
    init(repository: PostRepository) {
        self.repository = repository
    }
    
    func fetchPosts(page: Int) -> Observable<[Post]> {
        return repository.fetchPosts(page: page, pageSize: pageSize)
    }
    
    func toggleLike(postId: String) -> Observable<Bool> {
        return repository.toggleLike(postId: postId)
    }
}

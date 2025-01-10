//
//  PostRepository.swift
//  zSwing
//
//  Created by USER on 1/10/25.
//

import RxSwift

protocol PostRepository {
    func fetchPosts(page: Int, pageSize: Int) -> Observable<[Post]>
    func toggleLike(postId: String) -> Observable<Bool>
}

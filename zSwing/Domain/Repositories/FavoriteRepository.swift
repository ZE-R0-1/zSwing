//
//  FavoriteRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift

protocol FavoriteRepository {
    func isFavorite(playgroundId: String) -> Observable<Bool>
    func toggleFavorite(playgroundId: String) -> Observable<Bool>
}

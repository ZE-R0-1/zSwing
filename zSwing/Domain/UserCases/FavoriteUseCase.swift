//
//  FavoriteUseCase.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift

protocol FavoriteUseCase {
    func toggleFavorite(playgroundId: String) -> Observable<Bool>
}

final class DefaultFavoriteUseCase: FavoriteUseCase {
    private let favoriteRepository: FavoriteRepository
    
    init(favoriteRepository: FavoriteRepository) {
        self.favoriteRepository = favoriteRepository
    }
    
    func toggleFavorite(playgroundId: String) -> Observable<Bool> {
        return favoriteRepository.toggleFavorite(playgroundId: playgroundId)
    }
}

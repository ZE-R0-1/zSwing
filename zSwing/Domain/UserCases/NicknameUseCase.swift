//
//  NicknameUseCase.swift
//  zSwing
//
//  Created by USER on 11/11/24.
//

import RxSwift

protocol NicknameUseCase {
    func saveNickname(_ nickname: String) -> Observable<Result<Void, Error>>
    func checkNicknameExists() -> Observable<Bool>
}

class DefaultNicknameUseCase: NicknameUseCase {
    private let repository: NicknameRepository
    
    init(repository: NicknameRepository) {
        self.repository = repository
    }
    
    func saveNickname(_ nickname: String) -> Observable<Result<Void, Error>> {
        return repository.saveNickname(nickname)
    }
    
    func checkNicknameExists() -> Observable<Bool> {
        return repository.checkNicknameExists()
    }
}

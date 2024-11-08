//
//  ProfileUseCase.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import RxSwift

protocol ProfileUseCase {
    func logout() -> Observable<Result<Void, Error>>
    func withdraw() -> Observable<Result<Void, Error>>
    func getCurrentUser() -> Observable<Result<User, Error>>
}

class DefaultProfileUseCase: ProfileUseCase {
    private let repository: ProfileRepository
    
    init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    func logout() -> Observable<Result<Void, Error>> {
        return repository.logout()
    }
    
    func withdraw() -> Observable<Result<Void, Error>> {
        return repository.withdraw()
    }
    
    func getCurrentUser() -> Observable<Result<User, Error>> {
        return repository.getCurrentUser()
    }
}

//
//  SignInUseCase.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import Foundation
import RxSwift

protocol SignInUseCase {
    func execute(with provider: LoginMethod, credentials: [String: Any]) -> Observable<Result<User, Error>>
}

class DefaultSignInUseCase: SignInUseCase {
    private let repository: AuthenticationRepository
    
    init(repository: AuthenticationRepository) {
        self.repository = repository
    }
    
    func execute(with provider: LoginMethod, credentials: [String: Any]) -> Observable<Result<User, Error>> {
        return repository.signIn(with: provider, credentials: credentials)
    }
}

//
//  AuthenticationRepository.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit
import RxSwift

protocol AuthenticationRepository {
    func signIn(with provider: LoginMethod, credentials: [String: Any]) -> Observable<Result<User, Error>>
    func checkUserExists(userId: String) -> Observable<Bool>
}

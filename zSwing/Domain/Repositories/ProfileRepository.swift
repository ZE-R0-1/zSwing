//
//  ProfileRepository.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import RxSwift

protocol ProfileRepository {
    func logout() -> Observable<Result<Void, Error>>
    func withdraw() -> Observable<Result<Void, Error>>
    func getCurrentUser() -> Observable<Result<User, Error>>
}

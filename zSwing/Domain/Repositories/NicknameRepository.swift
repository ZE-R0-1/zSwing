//
//  NicknameRepository.swift
//  zSwing
//
//  Created by USER on 11/11/24.
//

import RxSwift

protocol NicknameRepository {
    func saveNickname(_ nickname: String) -> Observable<Result<Void, Error>>
    func checkNicknameExists() -> Observable<Bool>
}

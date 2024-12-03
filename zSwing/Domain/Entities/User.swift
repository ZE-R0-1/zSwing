//
//  User.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import Foundation

struct User {
    let id: String
    let email: String
    let loginMethod: LoginMethod
}

enum LoginMethod: String {
    case kakao
    case google
    case apple
}

enum AuthError: Error {
    case invalidCredentials
    case networkError
    case userNotFound
    case unknown
    case invalidToken
    case missingEmail
}

enum LoginResult {
    case success(hasNickname: Bool)
    case failure(Error)
}

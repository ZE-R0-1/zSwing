//
//  AppDIContainer.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import Foundation

class AppDIContainer {
    static let shared = AppDIContainer()
    
    lazy var authenticationRepository: AuthenticationRepository = {
        return DefaultAuthenticationRepository()
    }()
    
    func makeLoginViewController() -> LoginViewController {
        let signInUseCase = DefaultSignInUseCase(repository: authenticationRepository)
        let viewModel = LoginViewModel(signInUseCase: signInUseCase)
        return LoginViewController(viewModel: viewModel)
    }
}

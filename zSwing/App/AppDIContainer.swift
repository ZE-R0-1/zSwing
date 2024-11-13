//
//  AppDIContainer.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit

final class AppDIContainer {
    static let shared = AppDIContainer()
    private init() {}
    
    private lazy var authRepository = DefaultAuthenticationRepository()
    private lazy var authService: FirebaseAuthServiceProtocol = FirebaseAuthService()
    
    func makeMainTabCoordinator(navigationController: UINavigationController) -> MainTabCoordinator {
        return DefaultMainTabCoordinator(
            navigationController: navigationController,
            diContainer: self
        )
    }
    
    func makeLoadingViewController() -> LoadingViewController {
        return LoadingViewController()
    }

    func makeLoginViewController() -> LoginViewController {
        let signInUseCase = DefaultSignInUseCase(repository: authRepository)
        let nicknameUseCase = DefaultNicknameUseCase(repository: DefaultNicknameRepository())
        let viewModel = LoginViewModel(
            signInUseCase: signInUseCase,
            nicknameUseCase: nicknameUseCase
        )
        return LoginViewController(viewModel: viewModel)
    }
    
    func makeNicknameViewController() -> NicknameViewController {
        let nicknameUseCase = DefaultNicknameUseCase(
            repository: DefaultNicknameRepository()
        )
        let viewModel = NicknameViewModel(useCase: nicknameUseCase)
        return NicknameViewController(viewModel: viewModel)
    }
    
    func makeHomeViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        return vc
    }
    
    func makeMapViewController() -> UIViewController {
        return MapViewController(viewModel: MapViewModel(
            useCase: DefaultMapUseCase(
                repository: DefaultMapRepository()
            )
        ))
    }
    
    func makeProfileViewController() -> UIViewController {
        return ProfileViewController(viewModel: ProfileViewModel(
            useCase: DefaultProfileUseCase(
                repository: DefaultProfileRepository(
                    firebaseAuthService: authService
                )
            )
        ))
    }
}

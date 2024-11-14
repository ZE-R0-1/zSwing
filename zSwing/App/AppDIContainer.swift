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
    
    // MARK: - Repositories
    private lazy var authRepository = DefaultAuthenticationRepository()
    private lazy var authService: FirebaseAuthServiceProtocol = FirebaseAuthService()
    private lazy var playgroundRepository: PlaygroundRepository = DefaultPlaygroundRepository()
    private lazy var locationRepository: MapRepository = DefaultMapRepository()
    
    // MARK: - UseCases
    private lazy var playgroundUseCase: PlaygroundUseCase = DefaultPlaygroundUseCase(
        repository: playgroundRepository
    )
    
    private lazy var mapUseCase: MapUseCase = DefaultMapUseCase(
        repository: locationRepository
    )
    
    // MARK: - ViewModels
    private func makeMapViewModel() -> MapViewModel {
        return MapViewModel(
            useCase: mapUseCase,
            playgroundUseCase: playgroundUseCase
        )
    }
    
    // MARK: - ViewControllers
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
        return MapViewController(viewModel: makeMapViewModel())
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

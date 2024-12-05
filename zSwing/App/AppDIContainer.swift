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
    
    // MARK: - Repositories & Services
    private lazy var authRepository = DefaultAuthenticationRepository()
    private lazy var authService: FirebaseAuthServiceProtocol = FirebaseAuthService()
    private lazy var playgroundRepository: PlaygroundRepository = DefaultPlaygroundRepository(firebaseService: firebasePlaygroundService)
    private lazy var locationRepository: MapRepository = DefaultMapRepository()
    private lazy var rideRepository: RideRepository = DefaultRideRepository()
    private lazy var firebasePlaygroundService: FirebasePlaygroundServiceProtocol = FirebasePlaygroundService()
    
    // MARK: - Coordinators
    func makeAuthCoordinator(navigationController: UINavigationController) -> AuthCoordinator {
        return DefaultAuthCoordinator(
            navigationController: navigationController,
            diContainer: self
        )
    }
    
    func makeMainTabCoordinator(navigationController: UINavigationController) -> MainTabCoordinator {
        return DefaultMainTabCoordinator(
            navigationController: navigationController,
            diContainer: self
        )
    }
    
    func makeMapCoordinator(navigationController: UINavigationController) -> MapCoordinator {
        return DefaultMapCoordinator(
            navigationController: navigationController,
            diContainer: self
        )
    }
    
    func makeProfileCoordinator(
        navigationController: UINavigationController,
        mainCoordinator: MainTabCoordinator
    ) -> ProfileCoordinator {
        return DefaultProfileCoordinator(
            navigationController: navigationController,
            diContainer: self,
            mainCoordinator: mainCoordinator
        )
    }
    
    // MARK: - UseCases
    private func makeSignInUseCase() -> SignInUseCase {
        return DefaultSignInUseCase(repository: authRepository)
    }
    
    private func makeNicknameUseCase() -> NicknameUseCase {
        return DefaultNicknameUseCase(repository: DefaultNicknameRepository())
    }
    
    private func makeProfileUseCase() -> ProfileUseCase {
        return DefaultProfileUseCase(
            repository: DefaultProfileRepository(firebaseAuthService: authService)
        )
    }
    
    private func makeMapUseCase() -> MapUseCase {
        return DefaultMapUseCase(repository: locationRepository)
    }
    
//    private func makePlaygroundUseCase() -> PlaygroundUseCase {
//        return DefaultPlaygroundUseCase(repository: playgroundRepository)
//    }
    
    private func makePlaygroundListUseCase() -> PlaygroundListUseCase {
        return DefaultPlaygroundListUseCase(
            repository: DefaultPlaygroundRepository(
                firebaseService: firebasePlaygroundService
            )
        )
    }
    
    // MARK: - ViewModels
    private func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(
            signInUseCase: makeSignInUseCase(),
            nicknameUseCase: makeNicknameUseCase()
        )
    }
    
    private func makeNicknameViewModel() -> NicknameViewModel {
        return NicknameViewModel(useCase: makeNicknameUseCase())
    }
    
    private func makeMapViewModel() -> MapViewModel {
        return MapViewModel(
            useCase: makeMapUseCase(),
            playgroundListViewModel: makePlaygroundListViewModel()
        )
    }
    
    private func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(useCase: makeProfileUseCase())
    }
    
    private func makePlaygroundListViewModel() -> PlaygroundListViewModel {
        return PlaygroundListViewModel(playgroundUseCase: makePlaygroundListUseCase())
    }
    
    // MARK: - ViewControllers
    func makeLoginViewController() -> LoginViewController {
        return LoginViewController(viewModel: makeLoginViewModel())
    }
    
    func makeNicknameViewController() -> NicknameViewController {
        return NicknameViewController(viewModel: makeNicknameViewModel())
    }
    
    func makeMapViewController() -> MapViewController {
        return MapViewController(viewModel: makeMapViewModel())
    }
    
    func makeProfileViewController() -> ProfileViewController {
        return ProfileViewController(viewModel: makeProfileViewModel())
    }
    
    func makePlaygroundListViewController() -> PlaygroundListViewController {
        return PlaygroundListViewController(viewModel: makePlaygroundListViewModel())
    }
    
    func makeHomeViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        return vc
    }
    
    func makeLoadingViewController() -> LoadingViewController {
        return LoadingViewController()
    }
}

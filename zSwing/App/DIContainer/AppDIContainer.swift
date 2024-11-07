//
//  AppDIContainer.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit
import RxSwift

final class AppDIContainer {
    static let shared = AppDIContainer()
    
    // MARK: - Repositories
    lazy var authenticationRepository: AuthenticationRepository = {
        return DefaultAuthenticationRepository()
    }()
    
    // MARK: - Auth
    func makeLoginViewController() -> LoginViewController {
        let signInUseCase = DefaultSignInUseCase(repository: authenticationRepository)
        let viewModel = LoginViewModel(signInUseCase: signInUseCase)
        return LoginViewController(viewModel: viewModel)
    }
    
    // MARK: - MainTab
    func makeMainTabCoordinator(navigationController: UINavigationController) -> MainTabCoordinator {
        return DefaultMainTabCoordinator(navigationController: navigationController, diContainer: self)
    }
    
    func makeMainTabBarController(coordinator: MainTabCoordinator) -> MainTabBarController {
        let viewModel = MainTabBarViewModel(coordinator: coordinator)
        let tabBarController = MainTabBarController()
        tabBarController.configure(with: viewModel)
        return tabBarController
    }
    
    // MARK: - Home
//    func makeHomeViewController() -> HomeViewController {
//        let viewModel = makeHomeViewModel()
//        return HomeViewController(viewModel: viewModel)
//    }
//    
//    private func makeHomeViewModel() -> HomeViewModel {
//        // TODO: Implement PhotoUploadViewModel and its dependencies
//        return HomeViewModel()
//    }
    
    // MARK: - Map
//    func makeMapViewController() -> MapViewController {
//        let viewModel = makeMapViewModel()
//        return MapViewController(viewModel: viewModel)
//    }
//    
//    private func makeMapViewModel() -> MapViewModel {
//        // TODO: Implement MapViewModel and its dependencies
//        return MapViewModel()
//    }
    
    // MARK: - Profile
    func makeProfileViewController() -> ProfileViewController {
        let viewModel = makeProfileViewModel()
        return ProfileViewController(viewModel: viewModel)
    }
    
    private func makeProfileViewModel() -> ProfileViewModel {
        // TODO: Implement ProfileViewModel and its dependencies
        return ProfileViewModel()
    }
    
    // MARK: - Services
    private lazy var firebaseAuthService: FirebaseAuthServiceProtocol = {
        return FirebaseAuthService()
    }()
    
    // MARK: - Use Cases
    private func makeSignInUseCase() -> SignInUseCase {
        return DefaultSignInUseCase(repository: authenticationRepository)
    }
}

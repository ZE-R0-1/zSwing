//
//  AppDIContainer.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit
import RxSwift

final class AppDIContainer {
    // MARK: - Shared Instance
    static let shared = AppDIContainer()
    
    private init() {
        print("🏗 Initializing AppDIContainer")
    }
    
    // MARK: - Repositories
    lazy var authenticationRepository: AuthenticationRepository = {
        print("📦 Creating AuthenticationRepository")
        return DefaultAuthenticationRepository()
    }()
    
    private lazy var profileRepository: ProfileRepository = {
        print("📦 Creating ProfileRepository")
        return DefaultProfileRepository(firebaseAuthService: firebaseAuthService)
    }()
    
    // MARK: - Services
    private lazy var firebaseAuthService: FirebaseAuthServiceProtocol = {
        print("🔥 Creating FirebaseAuthService")
        return FirebaseAuthService()
    }()
    
    // MARK: - Use Cases
    private func makeSignInUseCase() -> SignInUseCase {
        print("🔨 Creating SignInUseCase")
        return DefaultSignInUseCase(repository: authenticationRepository)
    }
    
    private func makeProfileUseCase() -> ProfileUseCase {
        print("🔨 Creating ProfileUseCase")
        return DefaultProfileUseCase(repository: profileRepository)
    }
    
    // MARK: - View Controllers & ViewModels
    func makeLoginViewController() -> LoginViewController {
        print("🎨 Creating LoginViewController")
        let signInUseCase = makeSignInUseCase()
        let viewModel = LoginViewModel(signInUseCase: signInUseCase)
        return LoginViewController(viewModel: viewModel)
    }
    
    func makeMainTabCoordinator(navigationController: UINavigationController) -> MainTabCoordinator {
        print("🎨 Creating MainTabCoordinator")
        let coordinator = DefaultMainTabCoordinator(
            navigationController: navigationController,
            diContainer: self
        )
        print("✅ MainTabCoordinator created")
        return coordinator
    }
    
    func makeProfileViewController() -> ProfileViewController {
        print("🎨 Creating ProfileViewController")
        let viewModel = makeProfileViewModel()
        return ProfileViewController(viewModel: viewModel)
    }
    
    private func makeProfileViewModel() -> ProfileViewModel {
        print("🔨 Creating ProfileViewModel")
        let useCase = makeProfileUseCase()
        return ProfileViewModel(useCase: useCase)
    }
    
    // MARK: - Temporary ViewControllers
    func makeHomeViewController() -> UIViewController {
        print("🏠 Creating HomeViewController")
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        
        // 임시 UI 추가 (테스트용)
        let label = UILabel()
        label.text = "홈 화면"
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    // MARK: - Map
    func makeMapViewController() -> UIViewController {
        print("🗺 Creating MapViewController")
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        
        // 임시 UI 추가 (테스트용)
        let label = UILabel()
        label.text = "지도 화면"
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
}

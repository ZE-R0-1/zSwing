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
    
    private func makeNicknameRepository() -> NicknameRepository {
        return DefaultNicknameRepository()
    }
    
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
    
    private func makeNicknameUseCase() -> NicknameUseCase {
        return DefaultNicknameUseCase(repository: makeNicknameRepository())
    }
    
    private func makeProfileUseCase() -> ProfileUseCase {
        print("🔨 Creating ProfileUseCase")
        return DefaultProfileUseCase(repository: profileRepository)
    }
    
    // MARK: - View Controllers & ViewModels
    func makeLoginViewController() -> LoginViewController {
        print("🎨 Creating LoginViewController")
        let signInUseCase = makeSignInUseCase()
        let nicknameUseCase = makeNicknameUseCase() // 추가
        let viewModel = LoginViewModel(
            signInUseCase: signInUseCase,
            nicknameUseCase: nicknameUseCase
        )
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
    
    func makeNicknameViewController() -> NicknameViewController {
        let viewModel = NicknameViewModel(useCase: makeNicknameUseCase())
        return NicknameViewController(viewModel: viewModel)
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
    private func makeMapRepository() -> MapRepository {
        print("📦 Creating MapRepository")
        return DefaultMapRepository()
    }
    
    private func makeMapUseCase() -> MapUseCase {
        print("🔨 Creating MapUseCase")
        return DefaultMapUseCase(repository: makeMapRepository())
    }
    
    private func makeMapViewModel() -> MapViewModel {
        print("🔨 Creating MapViewModel")
        return MapViewModel(useCase: makeMapUseCase())
    }
    
    func makeMapViewController() -> UIViewController {
        print("🗺 Creating MapViewController")
        let viewModel = makeMapViewModel()
        return MapViewController(viewModel: viewModel)
    }
}

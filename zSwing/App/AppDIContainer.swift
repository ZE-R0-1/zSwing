//
//  AppDIContainer.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit
import CoreLocation

final class AppDIContainer {
    static let shared = AppDIContainer()
    private init() {}
    
    // MARK: - Repositories & Services
    private lazy var authRepository = DefaultAuthenticationRepository()
    private lazy var authService: FirebaseAuthServiceProtocol = FirebaseAuthService()
    private lazy var playgroundRepository: PlaygroundRepository = DefaultPlaygroundRepository(firebaseService: firebasePlaygroundService)
    private lazy var mapRepository: MapRepository = DefaultMapRepository()
    private lazy var firebasePlaygroundService: FirebasePlaygroundServiceProtocol = FirebasePlaygroundService()
    private lazy var playgroundDetailRepository: PlaygroundDetailRepository = DefaultPlaygroundDetailRepository()
    private lazy var favoriteRepository: FavoriteRepository = DefaultFavoriteRepository()
    private lazy var reviewRepository: ReviewRepository = DefaultReviewRepository()
    private lazy var storageService: StorageServiceProtocol = FirebaseStorageService()
    private lazy var locationManager = LocationManager()
    
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
    
    func makeHomeCoordinator(navigationController: UINavigationController) -> HomeCoordinator {
        return DefaultHomeCoordinator(
            navigationController: navigationController,
            diContainer: self,
            locationManager: locationManager
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
        return DefaultMapUseCase(
            repository: mapRepository
        )
    }
    
    private func makePlaygroundListUseCase() -> PlaygroundListUseCase {
        return DefaultPlaygroundListUseCase(
            repository: playgroundRepository
        )
    }
    
    private func makePlaygroundDetailUseCase() -> PlaygroundDetailUseCase {
        return DefaultPlaygroundDetailUseCase(
            playgroundRepository: playgroundDetailRepository,
            favoriteRepository: favoriteRepository,
            reviewRepository: reviewRepository
        )
    }
    
    private func makeFavoriteUseCase() -> FavoriteUseCase {
        return DefaultFavoriteUseCase(
            favoriteRepository: favoriteRepository
        )
    }
    
    private func makeReviewUseCase() -> ReviewUseCase {
        return DefaultReviewUseCase(
            reviewRepository: reviewRepository,
            storageService: storageService
        )
    }
    
    private func makePostUseCase() -> PostUseCase {
        return DefaultPostUseCase(repository: makePostRepository())
    }
    
    private func makePostRepository() -> PostRepository {
        return DefaultPostRepository()
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
    
    func makeHomeViewModel(coordinator: HomeCoordinator) -> HomeViewModel {
        return HomeViewModel(coordinator: coordinator)
    }
    
    private func makeFeedViewModel() -> FeedViewModel {
        return FeedViewModel(useCase: makePostUseCase())
    }
    
    private func makeMapViewModel() -> MapViewModel {
        return MapViewModel(
            useCase: makeMapUseCase(),
            playgroundUseCase: makePlaygroundListUseCase()
        )
    }
    
    private func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(useCase: makeProfileUseCase())
    }
    
    private func makePlaygroundListViewModel() -> PlaygroundListViewModel {
        return PlaygroundListViewModel(playgroundUseCase: makePlaygroundListUseCase())
    }
    
    private func makePlaygroundViewModel(playground: Playground1, currentLocation: CLLocation?) -> PlaygroundViewModel {
        return PlaygroundViewModel(
            playground: playground,
            currentLocation: currentLocation,
            playgroundDetailUseCase: makePlaygroundDetailUseCase(),
            favoriteUseCase: makeFavoriteUseCase(),
            reviewUseCase: makeReviewUseCase()
        )
    }
    
    // MARK: - ViewControllers
    func makeLoginViewController() -> LoginViewController {
        return LoginViewController(viewModel: makeLoginViewModel())
    }
    
    func makeNicknameViewController() -> NicknameViewController {
        return NicknameViewController(viewModel: makeNicknameViewModel())
    }
    
    func makeHomeViewController(coordinator: HomeCoordinator) -> UIViewController {
        let viewModel = makeHomeViewModel(coordinator: coordinator)
        return HomeViewController(viewModel: viewModel)
    }
    
    func makeMapViewController(coordinator: MapCoordinator) -> MapViewController {
        return MapViewController(
            viewModel: makeMapViewModel(),
            coordinator: coordinator,
            diContainer: self
        )
    }
    
    func makeProfileViewController() -> ProfileViewController {
        return ProfileViewController(viewModel: makeProfileViewModel())
    }
    
    func makePlaygroundListViewController() -> PlaygroundListViewController {
        return PlaygroundListViewController(
            viewModel: makePlaygroundListViewModel(),
            diContainer: self
        )
    }
    
    func makePlaygroundView(playground: Playground1, currentLocation: CLLocation?) -> PlaygroundViewController {
        return PlaygroundViewController(
            viewModel: makePlaygroundViewModel(
                playground: playground,
                currentLocation: currentLocation
            )
        )
    }
    
    func makeFeedViewController() -> UIViewController {
        return FeedViewController(viewModel: makeFeedViewModel())
    }
    
    func makeLoadingViewController() -> LoadingViewController {
        return LoadingViewController()
    }
}

////
////  ProfileCoordinator.swift
////  zSwing
////
////  Created by USER on 12/2/24.
////
//
//import UIKit
//import RxSwift
//
//protocol ProfileCoordinator: Coordinator {
//    func showProfile()
//    func showSettings()
//    func logout()
//    func withdraw()
//    func showAlert(title: String, message: String)
//    func showConfirmation(message: String, completion: @escaping (Bool) -> Void)
//}
//
//class DefaultProfileCoordinator: ProfileCoordinator {
//    let navigationController: UINavigationController
//    private let diContainer: AppDIContainer
//    private let mainCoordinator: MainTabCoordinator
//    private let disposeBag = DisposeBag()
//    
//    init(navigationController: UINavigationController,
//         diContainer: AppDIContainer,
//         mainCoordinator: MainTabCoordinator) {
//        self.navigationController = navigationController
//        self.diContainer = diContainer
//        self.mainCoordinator = mainCoordinator
//    }
//    
//    func start() {
//        showProfile()
//    }
//    
//    func showProfile() {
//        let profileVC = makeProfileViewController()
//        navigationController.setViewControllers([profileVC], animated: false)
//    }
//    
//    func showSettings() {
//        let settingsVC = UIViewController()
//        settingsVC.title = "설정"
//        settingsVC.view.backgroundColor = .white
//        navigationController.pushViewController(settingsVC, animated: true)
//    }
//    
//    func logout() {
//        print("🔄 Profile coordinator: Starting logout")
//        UserDefaults.standard.set(true, forKey: "hasNickname")
//        print("🔄 Profile coordinator: Calling switchToAuth")
//        mainCoordinator.switchToAuth()
//        print("🔄 Profile coordinator: switchToAuth called")
//    }
//    
//    func withdraw() {
//        UserDefaults.standard.removeObject(forKey: "hasNickname")
//        mainCoordinator.switchToAuth()
//    }
//    
//    func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "확인", style: .default))
//        navigationController.present(alert, animated: true)
//    }
//    
//    func showConfirmation(message: String, completion: @escaping (Bool) -> Void) {
//        let alert = UIAlertController(title: "확인", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
//            completion(false)
//        })
//        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
//            completion(true)
//        })
//        navigationController.present(alert, animated: true)
//    }
//    
//    private func makeProfileViewController() -> ProfileViewController {
//        let useCase = DefaultProfileUseCase(
//            repository: DefaultProfileRepository(
//                firebaseAuthService: FirebaseAuthService()
//            )
//        )
//        let viewModel = ProfileViewModel(useCase: useCase)
//        let viewController = ProfileViewController(viewModel: viewModel)
//        viewController.coordinator = self
//        return viewController
//    }
//}

//
//  SceneDelegate.swift
//  zSwing
//
//  Created by USER on 10/17/24.
//

import UIKit
import KakaoSDKAuth
import FirebaseCore
import GoogleSignIn
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var authCoordinator: AuthCoordinator?
    private let firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService()
    private let disposeBag = DisposeBag()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        self.window = window
        
        // 먼저 로딩 화면을 표시
        let loadingViewController = LoadingViewController()
        window.rootViewController = loadingViewController
        window.makeKeyAndVisible()
        
        // 인증 상태 체크
        checkAuthenticationState(window: window)
    }
    
    private func checkAuthenticationState(window: UIWindow) {
        firebaseAuthService.getCurrentUser()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                guard let self = self else { return }
                
                let navigationController = UINavigationController()
                
                if let user = user {
                    print("✅ Logged in user: \(user.email)")
                    
                    let mainTabCoordinator = AppDIContainer.shared.makeMainTabCoordinator(
                        navigationController: navigationController
                    )
                    mainTabCoordinator.start()
                    window.rootViewController = mainTabCoordinator.tabBarController
                    
                } else {
                    print("👤 No logged in user")
                    
                    self.authCoordinator = DefaultAuthCoordinator(
                        navigationController: navigationController,
                        diContainer: AppDIContainer.shared
                    )
                    window.rootViewController = navigationController
                    self.authCoordinator?.start()
                }
            })
            .disposed(by: disposeBag)
    }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            } else if let clientId = FirebaseApp.app()?.options.clientID {
                let config = GIDConfiguration(clientID: clientId)
                GIDSignIn.sharedInstance.configuration = config
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}

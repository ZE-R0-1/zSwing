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
            .delay(.milliseconds(800), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                guard let self = self else { return }
                
                let navigationController = UINavigationController()
                
                // 화면 전환 애니메이션
                let transition: () -> Void = {
                    if let user = user {
                        // 로그인된 사용자가 있는 경우
                        print("✅ Logged in user: \(user.email)")
                        
                        let mainTabCoordinator = AppDIContainer.shared.makeMainTabCoordinator(
                            navigationController: navigationController
                        )
                        mainTabCoordinator.start()
                        window.rootViewController = mainTabCoordinator.tabBarController
                        
                    } else {
                        // 로그인된 사용자가 없는 경우
                        print("👤 No logged in user")
                        
                        self.authCoordinator = DefaultAuthCoordinator(
                            navigationController: navigationController,
                            diContainer: AppDIContainer.shared
                        )
                        window.rootViewController = navigationController
                        self.authCoordinator?.start()
                    }
                }
                
                // 페이드 애니메이션으로 전환
                UIView.transition(with: window,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: transition)
                
            }, onError: { [weak self] error in
                print("❌ Auth check error: \(error)")
                
                let navigationController = UINavigationController()
                self?.authCoordinator = DefaultAuthCoordinator(
                    navigationController: navigationController,
                    diContainer: AppDIContainer.shared
                )
                
                // 에러 시에도 페이드 애니메이션으로 전환
                UIView.transition(with: window,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    window.rootViewController = navigationController
                    self?.authCoordinator?.start()
                })
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

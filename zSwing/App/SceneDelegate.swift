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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var authCoordinator: AuthCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        self.window = window
        
        let navigationController = UINavigationController()
        authCoordinator = DefaultAuthCoordinator(
            navigationController: navigationController,
            diContainer: AppDIContainer.shared
        )
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        authCoordinator?.start()
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

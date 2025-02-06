//
//  SceneDelegate.swift
//  zSwing
//
//  Created by USER on 10/17/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        self.window = window
        
        let navigationController = UINavigationController()
        let mainTabCoordinator = AppDIContainer.shared.makeMainTabCoordinator(
            navigationController: navigationController
        )
        mainTabCoordinator.start()
        window.rootViewController = mainTabCoordinator.tabBarController
        window.makeKeyAndVisible()
    }
}

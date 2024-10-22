//
//  SceneDelegate.swift
//  zSwing
//
//  Created by USER on 10/17/24.
//

import UIKit
import KakaoSDKAuth
import FirebaseFirestore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 초기 화면을 LaunchScreen으로 설정
        if let launchScreenViewController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() {
            window?.rootViewController = launchScreenViewController
        }
        
        window?.makeKeyAndVisible()
        
        // Firebase 초기화 및 인증 상태 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAuthenticationAndSetupInitialScreen()
        }
    }
    
    private func checkAuthenticationAndSetupInitialScreen() {
        if let currentUser = Auth.auth().currentUser {
            print("현재 로그인된 사용자 확인: \(currentUser.uid)")
            
            let db = Firestore.firestore()
            // 마지막 접속 시간 업데이트
            db.collection("users").document(currentUser.uid).updateData([
                "lastAccessDate": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("마지막 접속 시간 업데이트 실패: \(error)")
                } else {
                    print("마지막 접속 시간 업데이트 완료")
                }
            }
            
            // 기존의 사용자 정보 확인 로직
            db.collection("users").document(currentUser.uid).getDocument { [weak self] document, error in
                if let error = error {
                    print("사용자 정보 조회 중 오류 발생: \(error)")
                }
                
                DispatchQueue.main.async {
                    if let document = document, document.exists {
                        print("사용자 정보 존재: 메인 화면으로 이동합니다")
                        let mainTabBarController = MainTabBarController()
                        mainTabBarController.modalPresentationStyle = .fullScreen
                        mainTabBarController.modalTransitionStyle = .crossDissolve
                        
                        UIView.transition(with: self?.window ?? UIWindow(),
                                          duration: 0.3,
                                          options: .transitionCrossDissolve,
                                          animations: {
                            self?.window?.rootViewController = mainTabBarController
                        }, completion: nil)
                    } else {
                        print("사용자 정보 없음: 닉네임 설정 화면으로 이동합니다")
                        let nicknameVC = NicknameViewController()
                        nicknameVC.modalPresentationStyle = .fullScreen
                        nicknameVC.modalTransitionStyle = .crossDissolve
                        
                        UIView.transition(with: self?.window ?? UIWindow(),
                                          duration: 0.3,
                                          options: .transitionCrossDissolve,
                                          animations: {
                            self?.window?.rootViewController = nicknameVC
                        }, completion: nil)
                    }
                }
            }
        } else {
            print("로그인된 사용자 없음: 로그인 화면으로 이동합니다")
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            loginVC.modalTransitionStyle = .crossDissolve
            
            UIView.transition(with: window ?? UIWindow(),
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                self.window?.rootViewController = loginVC
            }, completion: nil)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

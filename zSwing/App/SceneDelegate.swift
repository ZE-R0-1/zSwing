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
import RxSwift
import GoogleSignIn
import FirebaseCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        print("Scene will connect") // 디버그 로그 추가

        // Window 초기화 및 설정
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white // 기본 배경색 설정
        self.window = window
        
        // AppCoordinator 초기화 및 시작
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()

        print("AppCoordinator started") // 디버그 로그 추가
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            // 카카오 로그인 URL 처리
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
            // 구글 로그인 URL 처리
            else if let clientId = FirebaseApp.app()?.options.clientID {
                let config = GIDConfiguration(clientID: clientId)
                GIDSignIn.sharedInstance.configuration = config
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
    
    // 앱 상태 변경 시 필요한 처리
    func sceneDidBecomeActive(_ scene: UIScene) {
        // 앱이 활성화될 때 필요한 작업 수행
        // 예: 네트워크 연결 상태 확인, 캐시 갱신 등
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // 앱이 비활성화될 때 필요한 작업 수행
        // 예: 진행 중인 작업 저장, 리소스 정리 등
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // 백그라운드로 전환될 때 필요한 작업 수행
        // 예: 중요 데이터 저장, 리소스 해제 등
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // 포그라운드로 전환될 때 필요한 작업 수행
        // 예: 데이터 새로고침, UI 업데이트 등
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // 씬이 해제될 때 필요한 정리 작업 수행
        // 예: 리소스 해제, 옵저버 제거 등
    }
}

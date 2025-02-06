//
//  AppDelegate.swift
//  zSwing
//
//  Created by USER on 10/17/24.
//

import UIKit
import FirebaseCore
import FirebaseStorage
import GoogleSignIn
import KakaoSDKCommon
import KakaoSDKAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 외부 서비스 초기화
        setupExternalServices()
        return true
    }
    
    private func setupExternalServices() {
        FirebaseApp.configure()
//        KakaoSDK.initSDK(appKey: "96bebf3c072c2e393d427de37f6b39e8")
    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        return AuthApi.isKakaoTalkLoginUrl(url) ? AuthController.handleOpenUrl(url: url) : GIDSignIn.sharedInstance.handle(url)
//    }
}

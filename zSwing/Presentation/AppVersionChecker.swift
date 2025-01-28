//
//  AppVersionChecker.swift
//  zSwing
//
//  Created by USER on 1/24/25.
//

import UIKit
import RxSwift

struct AppVersionConstants {
    static let appStoreId = "6740975128"
    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreId)"
}

final class AppVersionChecker {
    private let useCase: AppVersionUseCase
    private let disposeBag = DisposeBag()
    
    private struct AlertMessage {
        static let optional = (
            title: "새 버전 안내",
            message: "새로운 기능이 추가되었습니다. 업데이트 하시겠습니까?"
        )
        
        static let recommended = (
            title: "업데이트 권장",
            message: "원활한 사용을 위해 최신 버전으로 업데이트를 권장드립니다."
        )
        
        static let required = (
            title: "필수 업데이트",
            message: "서비스 이용을 위해 필수 업데이트가 필요합니다."
        )
    }
    
    init(useCase: AppVersionUseCase) {
        self.useCase = useCase
    }
    
    func checkVersion(in viewController: UIViewController) {
        useCase.checkAppVersion()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak viewController] version in
                self.showUpdateAlert(for: version.updateType, in: viewController)
            })
            .disposed(by: disposeBag)
    }
    
    private func showUpdateAlert(for type: UpdateType, in viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        switch type {
        case .optional:
            let alert = UIAlertController(
                title: AlertMessage.optional.title,
                message: AlertMessage.optional.message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
            alert.addAction(UIAlertAction(title: "업데이트", style: .default) { _ in
                self.openAppStore()
            })
            viewController.present(alert, animated: true)
            
        case .recommended:
            let alert = UIAlertController(
                title: AlertMessage.recommended.title,
                message: AlertMessage.recommended.message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "다음에", style: .cancel))
            alert.addAction(UIAlertAction(title: "업데이트", style: .default) { _ in
                self.openAppStore()
            })
            viewController.present(alert, animated: true)
            
        case .required:
            let alert = UIAlertController(
                title: AlertMessage.required.title,
                message: AlertMessage.required.message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "업데이트", style: .default) { _ in
                self.openAppStore()
            })
            viewController.present(alert, animated: true)
        }
    }
    
    private func openAppStore() {
        guard let url = URL(string: AppVersionConstants.appStoreURL) else { return }
        UIApplication.shared.open(url)
    }
}

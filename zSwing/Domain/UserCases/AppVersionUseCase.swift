//
//  AppVersionUseCase.swift
//  zSwing
//
//  Created by USER on 1/24/25.
//

import Foundation
import RxSwift

protocol AppVersionUseCase {
    func checkAppVersion() -> Observable<AppVersion>
}

final class DefaultAppVersionUseCase: AppVersionUseCase {
    private let repository: AppVersionRepository
    
    init(repository: AppVersionRepository) {
        self.repository = repository
    }
    
    func checkAppVersion() -> Observable<AppVersion> {
        return repository.checkAppVersion()
    }
}

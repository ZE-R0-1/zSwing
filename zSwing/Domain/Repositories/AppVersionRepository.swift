//
//  AppVersionRepository.swift
//  zSwing
//
//  Created by USER on 1/24/25.
//

import Foundation
import RxSwift

protocol AppVersionRepository {
    func checkAppVersion() -> Observable<AppVersion>
}

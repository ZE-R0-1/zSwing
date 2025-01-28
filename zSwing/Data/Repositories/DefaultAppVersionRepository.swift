//
//  DefaultAppVersionRepository.swift
//  zSwing
//
//  Created by USER on 1/24/25.
//

import Foundation
import RxSwift

final class DefaultAppVersionRepository: AppVersionRepository {
    func checkAppVersion() -> Observable<AppVersion> {
        return Observable.create { observer in
            let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
            let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
            
            guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
                return Disposables.create()
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let appStoreVersion = results.first?["version"] as? String else {
                    observer.onError(NSError(domain: "", code: -1))
                    return
                }
                
                let updateType = self.determineUpdateType(
                    currentVersion: currentVersion,
                    storeVersion: appStoreVersion
                )
                
                let version = AppVersion(
                    storeVersion: appStoreVersion,
                    currentVersion: currentVersion,
                    updateType: updateType
                )
                
                observer.onNext(version)
                observer.onCompleted()
            }
            
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func determineUpdateType(currentVersion: String, storeVersion: String) -> UpdateType {
        let current = versionToComponents(currentVersion)
        let store = versionToComponents(storeVersion)
        
        if store.major > current.major {
            return .required      // Major 버전 업데이트 (예: 1.0.0 → 2.0.0)
        } else if store.minor > current.minor {
            return .recommended   // Minor 버전 업데이트 (예: 1.0.0 → 1.1.0)
        } else if store.patch > current.patch {
            return .optional     // Patch 버전 업데이트 (예: 1.0.0 → 1.0.1)
        }
        
        return .optional
    }

    private func versionToComponents(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.components(separatedBy: ".").map { Int($0) ?? 0 }
        return (
            major: components.count > 0 ? components[0] : 0,
            minor: components.count > 1 ? components[1] : 0,
            patch: components.count > 2 ? components[2] : 0
        )
    }
}

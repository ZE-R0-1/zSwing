//
//  FirebaseStorageService.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import FirebaseStorage
import UIKit
import RxSwift

protocol StorageServiceProtocol {
    func uploadImages(images: [UIImage], path: String) -> Observable<[String]>
    func deleteImages(urls: [String]) -> Observable<Void>
}

class FirebaseStorageService: StorageServiceProtocol {
    private let storage: Storage
    
    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }
    
    func uploadImages(images: [UIImage], path: String) -> Observable<[String]> {
        guard !images.isEmpty else {
            print("Storage - No images to upload")
            return .just([])
        }
        
        print("Storage - Starting upload of \(images.count) images")
        
        let uploadObservables = images.enumerated().map { (index, image) -> Observable<String> in
            return Observable.create { [weak self] observer in
                guard let self = self,
                      let imageData = image.jpegData(compressionQuality: 0.7) else {
                    print("Storage - Failed to convert image to data")
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]))
                    return Disposables.create()
                }
                
                // 파일명 생성 (timestamp 추가)
                let timestamp = Int(Date().timeIntervalSince1970)
                let filename = "\(timestamp)_\(index).jpg"  // 인덱스를 사용하여 더 간단한 파일명
                let fullPath = "\(path)/\(filename)"  // path를 그대로 사용
                
                print("Storage - Uploading image to path:", fullPath)
                
                let reference = self.storage.reference().child(fullPath)
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let uploadTask = reference.putData(imageData, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("Storage - Upload failed:", error.localizedDescription)
                        observer.onError(error)
                        return
                    }
                    
                    reference.downloadURL { url, error in
                        if let error = error {
                            print("Storage - Failed to get download URL:", error.localizedDescription)
                            observer.onError(error)
                        } else if let urlString = url?.absoluteString {
                            print("Storage - Successfully uploaded image. URL:", urlString)
                            observer.onNext(urlString)
                            observer.onCompleted()
                        }
                    }
                }
                
                uploadTask.observe(.progress) { snapshot in
                    let percentComplete = 100.0 * Double(snapshot.progress?.completedUnitCount ?? 0)
                        / Double(snapshot.progress?.totalUnitCount ?? 1)
                    print("Storage - Upload progress: \(percentComplete)%")
                }
                
                return Disposables.create {
                    uploadTask.cancel()
                }
            }
        }
        
        return Observable.zip(uploadObservables)
            .do(onNext: { urls in
                print("Storage - All images uploaded successfully. URLs:", urls)
            }, onError: { error in
                print("Storage - Error during upload process:", error.localizedDescription)
            })
    }

    func deleteImages(urls: [String]) -> Observable<Void> {
        // 빈 배열이면 바로 완료
        guard !urls.isEmpty else {
            return .just(())
        }
        
        // 각 URL에 대한 삭제 Observable 생성
        let deleteObservables = urls.map { urlString -> Observable<Void> in
            return Observable.create { [weak self] observer in
                guard let self = self,
                      let url = URL(string: urlString),
                      url.host?.contains("firebasestorage.googleapis.com") == true else {
                    observer.onNext(())
                    observer.onCompleted()
                    return Disposables.create()
                }
                
                // URL에서 경로 추출
                let path = url.path.replacingOccurrences(of: "/v0/b/[^/]+/o/", with: "", options: .regularExpression)
                                 .removingPercentEncoding ?? ""
                
                let reference = self.storage.reference().child(path)
                
                reference.delete { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
                
                return Disposables.create()
            }
        }
        
        return Observable.zip(deleteObservables).map { _ in }
    }
}

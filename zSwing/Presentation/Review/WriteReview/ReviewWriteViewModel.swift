//
//  ReviewWriteViewModel.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import Foundation
import RxSwift
import RxRelay
import UIKit

class ReviewWriteViewModel {
    // MARK: - Dependencies
    private let reviewUseCase: ReviewUseCase
    private let playgroundId: String
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let imagesSelected = PublishRelay<[UIImage]>()
    let imageRemoved = PublishRelay<Int>() // 인덱스
    let textChanged = PublishRelay<String>()
    let ratingChanged = PublishRelay<Double>()
    let submitTapped = PublishRelay<Void>()
    
    // MARK: - Outputs
    let selectedImages = BehaviorRelay<[UIImage]>(value: [])
    let canAddMoreImages = BehaviorRelay<Bool>(value: true)
    let isSubmitEnabled = BehaviorRelay<Bool>(value: false)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let submitCompleted = PublishRelay<Void>()
    
    // MARK: - Private Properties
    private let maxImages = 5
    private let minTextLength = 10
    private var currentText = ""
    private var currentRating: Double = 0
    
    // MARK: - Initialization
    init(reviewUseCase: ReviewUseCase, playgroundId: String) {
        self.reviewUseCase = reviewUseCase
        self.playgroundId = playgroundId
        
        // 초기에 기본 이미지 설정
        let defaultImage = UIImage(systemName: "photo.fill") ?? UIImage()
        selectedImages.accept([defaultImage])  // 시작할 때 기본 이미지로 초기화
        
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // 이미지 선택 처리
        imagesSelected
            .withLatestFrom(selectedImages) { (newImages, currentImages) -> [UIImage] in
                // 새로운 이미지가 추가될 때만 기본 이미지 제거
                let updatedCurrentImages = newImages.isEmpty ? currentImages : {
                    if currentImages.count == 1 && currentImages[0].size == UIImage(systemName: "photo.fill")?.size {
                        return []
                    }
                    return currentImages
                }()
                
                let allImages = updatedCurrentImages + newImages
                return Array(allImages.prefix(self.maxImages))
            }
            .do(onNext: { [weak self] images in
                self?.canAddMoreImages.accept(images.count < self?.maxImages ?? 0)
            })
            .bind(to: selectedImages)
            .disposed(by: disposeBag)
        
        // 이미지 제거 처리
        imageRemoved
            .withLatestFrom(selectedImages) { (index, images) -> [UIImage] in
                var updatedImages = images
                guard index < updatedImages.count else { return images }
                updatedImages.remove(at: index)
                return updatedImages
            }
            .do(onNext: { [weak self] images in
                self?.canAddMoreImages.accept(images.count < self?.maxImages ?? 0)
            })
            .bind(to: selectedImages)
            .disposed(by: disposeBag)
        
        // 텍스트 변경 처리
        textChanged
            .do(onNext: { [weak self] text in
                self?.currentText = text
                self?.updateSubmitButtonState()
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 별점 변경 처리
        ratingChanged
            .do(onNext: { [weak self] rating in
                self?.currentRating = rating
                self?.updateSubmitButtonState()
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 제출 처리
        submitTapped
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
                print("Review write attempt with:")
                print("Content:", self?.currentText ?? "")
                print("Rating:", self?.currentRating ?? 0)
                print("Images count:", self?.selectedImages.value.count ?? 0)
            })
            .withLatestFrom(selectedImages)
            .flatMapLatest { [weak self] images -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.reviewUseCase.writeReview(
                    playgroundId: self.playgroundId,
                    content: self.currentText,
                    rating: self.currentRating,
                    images: images
                )
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
                self?.submitCompleted.accept(())
            }, onError: { [weak self] error in
                self?.isLoading.accept(false)
                self?.error.accept(error)
            })
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func updateSubmitButtonState() {
        let isValid = currentText.count >= minTextLength && currentRating > 0
        isSubmitEnabled.accept(isValid)
    }
}

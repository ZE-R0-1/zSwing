//
//  ReviewUseCase.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import Foundation
import RxSwift
import UIKit

protocol ReviewUseCase {
    func writeReview(
        playgroundId: String,
        content: String,
        rating: Double,
        images: [UIImage]
    ) -> Observable<Void>
    
    func getReviews(
        playgroundId: String,
        sortBy: ReviewSortOption,
        page: Int
    ) -> Observable<[Review]>
    
    func updateReview(
        reviewId: String,
        content: String,
        rating: Double,
        currentImageUrls: [String],
        newImages: [UIImage]
    ) -> Observable<Void>
    
    func deleteReview(reviewId: String) -> Observable<Void>
    
    func toggleLike(reviewId: String) -> Observable<Bool>
}

class DefaultReviewUseCase: ReviewUseCase {
    private let reviewRepository: ReviewRepository
    private let storageService: StorageServiceProtocol
    private let pageSize: Int = 20
    
    init(
        reviewRepository: ReviewRepository,
        storageService: StorageServiceProtocol
    ) {
        self.reviewRepository = reviewRepository
        self.storageService = storageService
    }
    
    func writeReview(
        playgroundId: String,
        content: String,
        rating: Double,
        images: [UIImage]
    ) -> Observable<Void> {
        print("UseCase - Starting review write process")
        print("PlaygroundId:", playgroundId)
        
        // 이미지 저장 경로 수정
        let storagePath = "reviews/\(playgroundId)/images"
        
        return storageService
            .uploadImages(images: images, path: storagePath)
            .flatMap { [weak self] imageUrls -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                let review = Review(
                    id: "",
                    playgroundId: playgroundId,
                    userId: "",
                    content: content,
                    rating: rating,
                    imageUrls: imageUrls,
                    createdAt: Date(),
                    updatedAt: Date(),
                    likeCount: 0,
                    isLiked: false,
                    userName: "",
                    userProfileUrl: nil
                )
                
                return self.reviewRepository.createReview(review: review)
            }
    }
    
    func getReviews(
        playgroundId: String,
        sortBy: ReviewSortOption,
        page: Int
    ) -> Observable<[Review]> {
        return reviewRepository.fetchReviews(
            playgroundId: playgroundId,
            sortBy: sortBy,
            page: page,
            pageSize: pageSize
        )
    }
    
    func updateReview(
        reviewId: String,
        content: String,
        rating: Double,
        currentImageUrls: [String],
        newImages: [UIImage]
    ) -> Observable<Void> {
        // 새 이미지 업로드
        return storageService
            .uploadImages(
                images: newImages,
                path: "reviews/\(reviewId)"
            )
            .flatMap { [weak self] newImageUrls -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 기존 이미지 URL과 새 이미지 URL 합치기
                let allImageUrls = currentImageUrls + newImageUrls
                
                // 리뷰 업데이트
                let review = Review(
                    id: reviewId,
                    playgroundId: "", // Repository에서 조회
                    userId: "", // Repository에서 조회
                    content: content,
                    rating: rating,
                    imageUrls: allImageUrls,
                    createdAt: Date(), // Repository에서 조회
                    updatedAt: Date(),
                    likeCount: 0, // Repository에서 조회
                    isLiked: false,
                    userName: "", // Repository에서 조회
                    userProfileUrl: nil
                )
                
                return self.reviewRepository.updateReview(review: review)
            }
    }
    
    func deleteReview(reviewId: String) -> Observable<Void> {
        // 리뷰 조회하여 이미지 URL 획득
        return reviewRepository
            .fetchReviews(playgroundId: "", sortBy: .latest, page: 0, pageSize: 1)
            .compactMap { reviews -> [String]? in
                reviews.first { $0.id == reviewId }?.imageUrls
            }
            .flatMap { [weak self] imageUrls -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 이미지 삭제와 리뷰 삭제를 동시에 실행
                return Observable.zip(
                    self.storageService.deleteImages(urls: imageUrls),
                    self.reviewRepository.deleteReview(reviewId: reviewId)
                )
                .map { _ in }
            }
    }
    
    func toggleLike(reviewId: String) -> Observable<Bool> {
        return reviewRepository.toggleLike(reviewId: reviewId)
    }
}

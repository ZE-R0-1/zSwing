//
//  ReviewViewModel.swift
//  zSwing
//
//  Created by USER on 12/30/24.
//

import RxSwift
import RxRelay
import CoreLocation

class ReviewViewModel {
   // MARK: - Properties
   private let reviewUseCase: ReviewUseCase
   private let disposeBag = DisposeBag()
   
   // MARK: - Inputs
   let viewDidLoad = PublishRelay<Void>()
   let likeButtonTapped = PublishRelay<Void>()
   
   // MARK: - Outputs
   let review = BehaviorRelay<Review?>(value: nil)
   let isLiked = BehaviorRelay<Bool>(value: false)
   let likeCount = BehaviorRelay<Int>(value: 0)
   let error = PublishRelay<Error>()
   
   // MARK: - Initialization
   init(review: Review, reviewUseCase: ReviewUseCase) {
       self.reviewUseCase = reviewUseCase
       self.review.accept(review)
       self.isLiked.accept(review.isLiked)
       self.likeCount.accept(review.likeCount)
       
       setupBindings()
   }
   
   // MARK: - Private Methods
   private func setupBindings() {
       likeButtonTapped
           .withLatestFrom(review.compactMap { $0 })
           .flatMapLatest { [weak self] review -> Observable<Bool> in
               guard let self = self else { return .empty() }
               return self.reviewUseCase.toggleLike(reviewId: review.id)
           }
           .do(onError: { [weak self] error in
               self?.error.accept(error)
           })
           .subscribe(onNext: { [weak self] isLiked in
               self?.isLiked.accept(isLiked)
               let currentCount = self?.likeCount.value ?? 0
               self?.likeCount.accept(isLiked ? currentCount + 1 : currentCount - 1)
               
               // 원본 리뷰 데이터도 업데이트
               if var updatedReview = self?.review.value {
                   updatedReview.isLiked = isLiked
                   updatedReview.likeCount = isLiked ? currentCount + 1 : currentCount - 1
                   self?.review.accept(updatedReview)
               }
           })
           .disposed(by: disposeBag)
   }
}

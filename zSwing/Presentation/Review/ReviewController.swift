//
//  ReviewController.swift
//  zSwing
//
//  Created by USER on 12/30/24.
//

import UIKit
import RxSwift
import RxCocoa

class ReviewController: UIViewController, UIScrollViewDelegate {
    // MARK: - Properties
    private let viewModel: ReviewViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private let profileView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "heart", withConfiguration: config), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill", withConfiguration: config), for: .selected)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .black
        collection.register(ReviewDetailImageCell.self, forCellWithReuseIdentifier: ReviewDetailImageCell.identifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .white
        control.pageIndicatorTintColor = .gray
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    init(viewModel: ReviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupConstraints()
        setupBindings()
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        view.addSubview(pageControl) // 페이지 컨트롤은 스크롤뷰 밖에 배치
        contentStackView.addArrangedSubview(imageCollectionView)
        contentStackView.addArrangedSubview(profileView)
        contentStackView.addArrangedSubview(contentLabel)
        contentStackView.setCustomSpacing(16, after: imageCollectionView)
        
        profileView.addSubview(profileImageView)
        profileView.addSubview(usernameLabel)
        profileView.addSubview(timeLabel)
        profileView.addSubview(ratingView)
        profileView.addSubview(likeButton)
        profileView.addSubview(likeCountLabel)
        
        // 별점 이미지 추가
        for _ in 0..<5 {
            let imageView = UIImageView(image: UIImage(systemName: "star.fill"))
            imageView.tintColor = .systemYellow
            ratingView.addArrangedSubview(imageView)
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissButtonTapped)
        )
    }
    
    private func setupConstraints() {
        let imageHeight = UIScreen.main.bounds.width
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 이미지 컬렉션뷰는 전체 너비 사용
            imageCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalToConstant: imageHeight),
            
            // Profile View 제약조건
            profileImageView.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // username과 rating은 profileImageView 기준으로 배치
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            usernameLabel.topAnchor.constraint(equalTo: profileView.topAnchor, constant: 16),
            
            timeLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            
            ratingView.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            ratingView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            ratingView.bottomAnchor.constraint(equalTo: profileView.bottomAnchor, constant: -16),
            
            // 좋아요 버튼과 카운트 수정: centerY 사용
            likeButton.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -16),
            likeButton.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            
            likeCountLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -8),
            likeCountLabel.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            
            contentLabel.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -16),
            
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupBindings() {
        // CollectionView 데이터 바인딩
        viewModel.review
            .compactMap { $0 }
            .map { $0.imageUrls }
            .do(onNext: { [weak self] urls in
                self?.pageControl.numberOfPages = urls.count
                self?.pageControl.isHidden = urls.count <= 1
            })
            .bind(to: imageCollectionView.rx.items(
                cellIdentifier: ReviewDetailImageCell.identifier,
                cellType: ReviewDetailImageCell.self
            )) { _, url, cell in
                cell.configure(with: url)
            }
            .disposed(by: disposeBag)
        
        // 이미지 셀 크기 설정
        imageCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        // 페이지 컨트롤 바인딩
        imageCollectionView.rx.contentOffset
            .map { [weak self] offset -> Int in
                guard let width = self?.imageCollectionView.bounds.width, width > 0 else { return 0 }
                return Int(round(offset.x / width))
            }
            .bind(to: pageControl.rx.currentPage)
            .disposed(by: disposeBag)
        
        // 프로필 정보 바인딩
        viewModel.review
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] review in
                self?.usernameLabel.text = review.userName
                self?.contentLabel.text = review.content
                
                // 별점 업데이트
                self?.updateRatingView(rating: review.rating)
                
                // 프로필 이미지 로드
                if let profileUrlString = review.userProfileUrl,
                   let profileUrl = URL(string: profileUrlString) {
                    URLSession.shared.dataTask(with: profileUrl) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.profileImageView.image = image
                            }
                        }
                    }.resume()
                } else {
                    self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                }
                
                // 시간 포맷팅
                let formatter = RelativeDateTimeFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.unitsStyle = .short
                let relativeDate = formatter.localizedString(for: review.createdAt, relativeTo: Date())
                self?.timeLabel.text = relativeDate
            })
            .disposed(by: disposeBag)
        
        // 좋아요 상태 바인딩
        viewModel.isLiked
            .subscribe(onNext: { [weak self] isLiked in
                self?.likeButton.isSelected = isLiked
            })
            .disposed(by: disposeBag)
        
        // 좋아요 수 바인딩
        viewModel.likeCount
            .map { "\($0)" }
            .bind(to: likeCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 좋아요 버튼 탭 바인딩
        likeButton.rx.tap
            .bind(to: viewModel.likeButtonTapped)
            .disposed(by: disposeBag)
    }
    private func updateRatingView(rating: Double) {
        let fullStarCount = Int(rating)
        let hasHalfStar = (rating - Double(fullStarCount)) >= 0.5
        
        ratingView.arrangedSubviews.enumerated().forEach { index, view in
            guard let imageView = view as? UIImageView else { return }
            
            if index < fullStarCount {
                imageView.image = UIImage(systemName: "star.fill")
            } else if index == fullStarCount && hasHalfStar {
                imageView.image = UIImage(systemName: "star.leadinghalf.filled")
            } else {
                imageView.image = UIImage(systemName: "star")
            }
            imageView.tintColor = .systemYellow
        }
    }
    
    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ReviewController: UICollectionViewDelegateFlowLayout {
   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
   }
}

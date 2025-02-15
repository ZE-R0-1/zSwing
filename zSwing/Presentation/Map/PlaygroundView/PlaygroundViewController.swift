//
//  PlaygroundView.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation

protocol PlaygroundViewDelegate: AnyObject {
    func playgroundViewDidDismiss(_ playgroundView: PlaygroundViewController)
}

final class PlaygroundViewController: UIViewController, ReviewWriteDelegate {
    // MARK: - Properties
    private let viewModel: PlaygroundViewModel
    private let disposeBag = DisposeBag()
    weak var delegate: PlaygroundViewDelegate?
    
    // MARK: - UI Components
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.numberOfLines = 0
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.tintColor = .systemBlue
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .darkGray
        button.backgroundColor = .clear
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()
    
    private let emptyReviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let emptyReviewLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 리뷰가 없어요\n첫 번째 리뷰를 작성해보세요!"
        label.textColor = .gray
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let reviewsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        collection.isScrollEnabled = false
        return collection
    }()
    
    private let writeReviewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("리뷰 작성", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    // MARK: - Initialization
    init(viewModel: PlaygroundViewModel) {
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
        setupConstraints()
        setupCollectionViewLayout()
        setupBindings()
        setupNotifications()
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // Create a horizontal stack view for the header buttons
        let headerButtonsStack = UIStackView()
        headerButtonsStack.axis = .horizontal
        headerButtonsStack.spacing = 8
        headerButtonsStack.addArrangedSubview(favoriteButton)
        headerButtonsStack.addArrangedSubview(closeButton)
        
        headerStackView.addArrangedSubview(nameLabel)
        headerStackView.addArrangedSubview(headerButtonsStack)
        
        emptyReviewView.addSubview(emptyReviewLabel)
        [emptyReviewView, emptyReviewLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        [headerStackView, addressLabel, distanceLabel, writeReviewButton,
         emptyReviewView, reviewsCollectionView].forEach {
            stackView.addArrangedSubview($0)
        }
        
        reviewsCollectionView.register(
            ReviewCell.self,
            forCellWithReuseIdentifier: ReviewCell.identifier
        )
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            reviewsCollectionView.heightAnchor.constraint(equalTo: reviewsCollectionView.widthAnchor),
            writeReviewButton.heightAnchor.constraint(equalToConstant: 44),
            emptyReviewView.heightAnchor.constraint(equalTo: emptyReviewView.widthAnchor),
            
            headerStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            
            emptyReviewLabel.centerXAnchor.constraint(equalTo: emptyReviewView.centerXAnchor),
            emptyReviewLabel.centerYAnchor.constraint(equalTo: emptyReviewView.centerYAnchor),
            
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),
            
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupCollectionViewLayout() {
        guard let layout = reviewsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let spacing: CGFloat = 1
        let numberOfItemsPerRow: CGFloat = 3
        
        let totalSpacing = (numberOfItemsPerRow - 1) * spacing
        let itemWidth = (UIScreen.main.bounds.width - 32 - totalSpacing) / numberOfItemsPerRow
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
    }
    
    private func setupBindings() {
        // Inputs
        favoriteButton.rx.tap
            .bind(to: viewModel.favoriteButtonTapped)
            .disposed(by: disposeBag)
        
        writeReviewButton.rx.tap
            .bind(to: viewModel.writeReviewButtonTapped)
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss()
            })
            .disposed(by: disposeBag)
        
        reviewsCollectionView.rx.itemSelected
            .withLatestFrom(viewModel.reviews) { indexPath, reviews in
                return reviews[indexPath.row]
            }
            .subscribe(onNext: { [weak self] review in
                self?.showReviewDetail(for: review)
            })
            .disposed(by: disposeBag)
        
        // Outputs
        viewModel.pfctNm
            .bind(to: nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.address
            .bind(to: addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.distance
            .bind(to: distanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isFavorite
            .map { isFavorite in
                UIImage(systemName: isFavorite ? "bookmark.fill" : "bookmark")
            }
            .bind(to: favoriteButton.rx.image())
            .disposed(by: disposeBag)
        
        // Reviews Empty State
        viewModel.reviews
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] reviews in
                if reviews.isEmpty {
                    self?.reviewsCollectionView.isHidden = true
                    self?.emptyReviewView.isHidden = false
                } else {
                    self?.reviewsCollectionView.isHidden = false
                    self?.emptyReviewView.isHidden = true
                }
            })
            .disposed(by: disposeBag)
        
        // Reviews Collection View Binding
        viewModel.reviews
            .bind(to: reviewsCollectionView.rx.items(
                cellIdentifier: ReviewCell.identifier,
                cellType: ReviewCell.self
            )) { _, review, cell in
                cell.configure(with: review)
            }
            .disposed(by: disposeBag)
        
        // 리뷰 작성 화면 표시
        viewModel.showReviewWrite
            .subscribe(onNext: { [weak self] playground in
                self?.showReviewWriteViewController(for: playground)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.rx.notification(NSNotification.Name("RefreshPlaygroundList"))
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.refreshReviewsTrigger.accept(())
            })
            .disposed(by: disposeBag)
    }
    
    private func showReviewWriteViewController(for playground: Playground1) {
        let reviewUseCase = DefaultReviewUseCase(
            reviewRepository: DefaultReviewRepository(),
            storageService: FirebaseStorageService()
        )
        
        let reviewWriteViewModel = ReviewWriteViewModel(
            reviewUseCase: reviewUseCase,
            playgroundId: playground.pfctSn
        )
        
        let reviewWriteVC = ReviewWriteViewController(viewModel: reviewWriteViewModel)
        reviewWriteVC.delegate = self
        let navigationController = UINavigationController(rootViewController: reviewWriteVC)
        
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: nil,
            action: nil
        )
        
        reviewWriteVC.navigationItem.leftBarButtonItem = doneButton
        
        doneButton.rx.tap
            .subscribe(onNext: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        present(navigationController, animated: true)
    }
    
    private func showReviewDetail(for review: Review) {
        let reviewUseCase = DefaultReviewUseCase(
            reviewRepository: DefaultReviewRepository(),
            storageService: FirebaseStorageService()
        )
        
        let viewModel = ReviewViewModel(
            review: review,
            reviewUseCase: reviewUseCase
        )
        
        let reviewController = ReviewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: reviewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            self.delegate?.playgroundViewDidDismiss(self)
        }
    }
    
    // MARK: - ReviewWriteDelegate
    func reviewWriteDidComplete() {
        viewModel.refreshReviewsTrigger.accept(())
    }
}

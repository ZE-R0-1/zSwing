//
//  HomeViewController.swift
//  zSwing
//
//  Created by USER on 1/8/25.
//

import UIKit
import RxSwift
import RxCocoa

class FeedViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: FeedViewModel
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .systemBackground
        collection.isPagingEnabled = true
        collection.showsVerticalScrollIndicator = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    // MARK: - Initialization
    init(viewModel: FeedViewModel) {
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
        setupCollectionView()
        setupBindings()
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.refreshControl = refreshControl
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: PostCell.identifier)
    }
    
    private func setupBindings() {
        // CollectionView 데이터 바인딩
        viewModel.posts
            .bind(to: collectionView.rx.items(
                cellIdentifier: PostCell.identifier,
                cellType: PostCell.self
            )) { [weak self] index, post, cell in
                cell.configure(with: post)
                cell.delegate = self
            }
            .disposed(by: disposeBag)
        
        // 새로고침 바인딩
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)
        
        // 로딩 상태 바인딩
        viewModel.isLoading
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        // 무한 스크롤 바인딩
        collectionView.rx.contentOffset
            .map { [weak self] offset in
                guard let self = self else { return false }
                let contentHeight = self.collectionView.contentSize.height
                let scrollViewHeight = self.collectionView.bounds.height
                let threshold: CGFloat = 100
                return offset.y + scrollViewHeight + threshold >= contentHeight
            }
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in }
            .bind(to: viewModel.loadMoreTrigger)
            .disposed(by: disposeBag)
        
        // 에러 처리
        viewModel.error
            .subscribe(onNext: { [weak self] error in
                self?.showError(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "오류",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let height = collectionView.frame.height
        return CGSize(width: width, height: height)
    }
}

// MARK: - PostCellDelegate
extension FeedViewController: PostCellDelegate {
    func postCell(_ cell: PostCell, didTapLikeButton postId: String) {
        viewModel.likeTrigger.accept(postId)
    }
}

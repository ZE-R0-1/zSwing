//
//  RideCategoryViewController.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit
import RxSwift
import RxCocoa

class RideCategoryViewController: UIViewController {
    private let viewModel: RideCategoryViewModel
    private let disposeBag = DisposeBag()
    private var isInitialScrollDone = false
    
    // MARK: - UI Components
    private let navigationStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "놀이터 찾기"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let spacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Initialization
    init(viewModel: RideCategoryViewModel) {
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
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isInitialScrollDone {
            let indexPath = IndexPath(item: viewModel.selectedIndex.value, section: 0)
            categoryCollectionView.scrollToItem(
                at: indexPath,
                at: .centeredHorizontally,
                animated: false
            )
            isInitialScrollDone = true
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        navigationStack.addArrangedSubview(backButton)
        navigationStack.addArrangedSubview(titleLabel)
        navigationStack.addArrangedSubview(spacerView)
        
        view.addSubview(navigationStack)
        view.addSubview(categoryCollectionView)
        
        NSLayoutConstraint.activate([
            navigationStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            navigationStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            navigationStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            navigationStack.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.widthAnchor.constraint(equalToConstant: 44),
            
            spacerView.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            
            categoryCollectionView.topAnchor.constraint(equalTo: navigationStack.bottomAnchor, constant: 14),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func bindViewModel() {
        // 뒤로가기 버튼 바인딩
        backButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 카테고리 데이터 바인딩
        viewModel.categories
            .bind(to: categoryCollectionView.rx.items(
                cellIdentifier: CategoryCell.identifier,
                cellType: CategoryCell.self
            )) { _, category, cell in
                cell.configure(with: category)
            }
            .disposed(by: disposeBag)
        
        // 초기 선택 상태 설정
        viewModel.selectedIndex
            .take(1)
            .subscribe(onNext: { [weak self] index in
                let indexPath = IndexPath(item: index, section: 0)
                self?.categoryCollectionView.selectItem(
                    at: indexPath,
                    animated: false,
                    scrollPosition: []
                )
            })
            .disposed(by: disposeBag)
        
        // 카테고리 선택 처리
        categoryCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.viewModel.categorySelected(at: indexPath.item)
                self?.categoryCollectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: true
                )
            })
            .disposed(by: disposeBag)
        
        // CollectionView 델리게이트 설정
        categoryCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RideCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let category = viewModel.categories.value[indexPath.item]
        let width = category.size(withAttributes: [.font: UIFont.systemFont(ofSize: 16)]).width + 20
        return CGSize(width: width, height: 44)
    }
}

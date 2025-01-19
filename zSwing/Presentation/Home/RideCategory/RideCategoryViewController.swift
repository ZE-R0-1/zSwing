//
//  RideCategoryViewController.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit
import RxSwift


class RideCategoryViewController: UIViewController {
    private let facility: PlaygroundFacility
    private let disposeBag = DisposeBag()
    
    private let categories: [String] = [
        "그네",
        "미끄럼틀",
        "정글짐",
        "공중기구",
        "회전기구",
        "흔들기구",
        "오르는기구",
        "건너는기구",
        "조합놀이대",
        "철봉",
        "늑목",
        "평균대"
    ]

    
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
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)  // 여기에 여백 추가
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Initialization
    init(facility: PlaygroundFacility) {
        self.facility = facility
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindUI()
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
            backButton.leadingAnchor.constraint(equalTo: navigationStack.leadingAnchor, constant: 8),
            
            spacerView.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            
            categoryCollectionView.topAnchor.constraint(equalTo: navigationStack.bottomAnchor, constant: 14),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func bindUI() {
        backButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        Observable.just(categories)
            .bind(to: categoryCollectionView.rx.items(
                cellIdentifier: CategoryCell.identifier,
                cellType: CategoryCell.self
            )) { _, category, cell in
                cell.configure(with: category)
            }
            .disposed(by: disposeBag)
        
        categoryCollectionView.selectItem(
            at: IndexPath(item: 0, section: 0),
            animated: false,
            scrollPosition: []
        )
        
        categoryCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                print("Selected category: \(self?.categories[indexPath.item] ?? "")")
                
                // 선택된 셀을 중앙으로 스크롤
                self?.categoryCollectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,  // 수평 중앙 정렬
                    animated: true
                )
            })
            .disposed(by: disposeBag)
        
        categoryCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RideCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let category = categories[indexPath.item]
        let width = category.size(withAttributes: [.font: UIFont.systemFont(ofSize: 16)]).width + 20
        return CGSize(width: width, height: 44)
    }
}

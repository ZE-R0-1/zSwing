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
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = HomeViewModel.themeColor
        button.setTitle("지도보기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 22
        
        // 그림자 효과 추가
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var playgroundListView: PlaygroundListView = {
        let view = PlaygroundListView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 1  // 명시적으로 초기값 설정
        return view
    }()
    
    private lazy var playgroundMapView: PlaygroundMapView = {
        let view = PlaygroundMapView(locationManager: viewModel.locationManager)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
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
        
        contentContainerView.addSubview(playgroundListView)
        contentContainerView.addSubview(playgroundMapView)

        view.addSubview(navigationStack)
        view.addSubview(categoryCollectionView)
        view.addSubview(shadowView)
        view.addSubview(contentContainerView)
        view.addSubview(toggleButton)
        
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
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 44),
            
            shadowView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor),
            shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowView.heightAnchor.constraint(equalToConstant: 1),
            
            contentContainerView.topAnchor.constraint(equalTo: shadowView.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            playgroundListView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            playgroundListView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            playgroundListView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            playgroundListView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            
            playgroundMapView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            playgroundMapView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            playgroundMapView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            playgroundMapView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),

            toggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            toggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            toggleButton.widthAnchor.constraint(equalToConstant: 90),
            toggleButton.heightAnchor.constraint(equalToConstant: 44)
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
        
        // 지도 영역 변경 바인딩
        playgroundMapView.visibleRegionObservable
            .subscribe(onNext: { [weak viewModel] region in
                viewModel?.updateVisibleRegion(region)
            })
            .disposed(by: disposeBag)
        
        // 맵뷰 어노테이션 선택 처리
        playgroundMapView.annotationSelected
            .subscribe(onNext: { [weak self] type in
                guard let self = self else { return }
                let bottomSheet = PlaygroundBottomSheetController(
                    type: type,
                    locationManager: self.viewModel.locationManager
                )
                
                // 바텀시트 dismiss 처리 추가
                bottomSheet.dismissObservable
                    .subscribe(onNext: { [weak self] in
                        self?.playgroundMapView.deselectAnnotation()
                    })
                    .disposed(by: self.disposeBag)
                
                self.present(bottomSheet, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 토글 버튼 상태 바인딩
        viewModel.isMapMode
            .map { $0 ? "목록보기" : "지도보기" }
            .bind(to: toggleButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        // 토글 버튼 탭 처리
        toggleButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.toggleViewMode()
            })
            .disposed(by: disposeBag)
            
        // 뷰 모드에 따른 컨텐츠 전환
        viewModel.isMapMode
            .subscribe(onNext: { [weak self] isMapMode in
                guard let self = self else { return }
                
                if isMapMode {
                    // 맵뷰로 전환
                    self.playgroundMapView.isHidden = false
                    self.playgroundMapView.alpha = 0
                    UIView.animate(withDuration: 0.3) {
                        self.playgroundListView.alpha = 0
                        self.playgroundMapView.alpha = 1
                    } completion: { _ in
                        self.playgroundListView.isHidden = true
                    }
                } else {
                    // 리스트뷰로 전환
                    self.playgroundListView.isHidden = false
                    self.playgroundListView.alpha = 0
                    UIView.animate(withDuration: 0.3) {
                        self.playgroundMapView.alpha = 0
                        self.playgroundListView.alpha = 1
                    } completion: { _ in
                        self.playgroundMapView.isHidden = true
                    }
                }
            })
            .disposed(by: disposeBag)

        playgroundListView.configure(with: viewModel)
        playgroundMapView.configure(with: viewModel)
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

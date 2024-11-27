//
//  PlaygroundDetailContent.swift
//  zSwing
//
//  Created by USER on 11/26/24.
//

import UIKit
import RxSwift
import RxCocoa

class PlaygroundDetailContent: UIView, BottomSheetContent {
    private let disposeBag = DisposeBag()
    
    // MARK: - Properties
    var contentScrollView: UIScrollView? { scrollView }
    private let playground: Playground
    let closeButtonTapped = PublishRelay<Void>()
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Header Section
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let gridView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let photoGridCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(PhotoGridCell.self, forCellWithReuseIdentifier: "PhotoGridCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    init(playground: Playground) {
        self.playground = playground
        super.init(frame: .zero)
        setupUI()
        configurePhotoGrid()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Add main components to stack view
        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(dividerView)
        contentStackView.addArrangedSubview(photoGridCollectionView)
        
        // Setup header
        headerView.addSubview(titleLabel)
        headerView.addSubview(locationLabel)
        headerView.addSubview(closeButton)
        
        // Configure header content
        titleLabel.text = playground.pfctNm
        locationLabel.text = "서울 영등포구 영등포 119"  // 실제 주소로 대체 필요
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header View
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            // Location Label
            locationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            // Close Button
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Divider
            dividerView.heightAnchor.constraint(equalToConstant: 0.2),
            
            // Photo Grid Collection View
            photoGridCollectionView.heightAnchor.constraint(equalTo: photoGridCollectionView.widthAnchor)
        ])
        
        // 닫기 버튼 탭 이벤트 바인딩
        closeButton.rx.tap
            .bind(to: closeButtonTapped)
            .disposed(by: disposeBag)
    }
    
    private func configurePhotoGrid() {
        photoGridCollectionView.delegate = self
        photoGridCollectionView.dataSource = self
        
        // Update layout
        if let layout = photoGridCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 1
            let width = (UIScreen.main.bounds.width - (spacing * 2)) / 3
            layout.itemSize = CGSize(width: width, height: width)
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
        }
    }
    
    func prepareForReuse() {
        // Clean up code
    }
}

// MARK: - Collection View Delegate & DataSource
extension PlaygroundDetailContent: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9 // 더미 데이터로 9개의 셀 표시
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoGridCell", for: indexPath) as! PhotoGridCell
        return cell
    }
}

// MARK: - PhotoGridCell
class PhotoGridCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "photo.fill")
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

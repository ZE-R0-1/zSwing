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
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
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
    
    // 닫기 버튼 추가
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 닫기 이벤트를 위한 릴레이
    let closeButtonTapped = PublishRelay<Void>()
    
    var contentScrollView: UIScrollView? { scrollView }
    var contentTitle: String { playground.pfctNm }
    private let playground: Playground
    
    init(playground: Playground) {
        self.playground = playground
        super.init(frame: .zero)
        setupUI()
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        addSubview(closeButton) // 닫기 버튼 추가
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            // 닫기 버튼 제약조건
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        setupContent()
    }
    
    private func setupBindings() {
        // 닫기 버튼 탭 이벤트 바인딩
        closeButton.rx.tap
            .bind(to: closeButtonTapped)
            .disposed(by: disposeBag)
    }
    
    private func setupContent() {
        // 이미지 섹션
        let imageSection = createImageSection()
        stackView.addArrangedSubview(imageSection)
        
        // 정보 섹션
        let infoSection = createInfoSection()
        stackView.addArrangedSubview(infoSection)
        
        // 놀이기구 섹션
        let ridesSection = createRidesSection()
        stackView.addArrangedSubview(ridesSection)
    }
    
    private func createImageSection() -> UIView {
        let containerView = UIView()
        containerView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        let imageView = UIImageView()
        imageView.backgroundColor = .systemGray6
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.image = UIImage(systemName: "photo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createInfoSection() -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = playground.pfctNm
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let addressLabel = UILabel()
        addressLabel.text = "주소 정보"  // 실제 주소로 대체 필요
        addressLabel.font = .systemFont(ofSize: 16)
        addressLabel.textColor = .systemGray
        addressLabel.numberOfLines = 0
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(addressLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createRidesSection() -> UIView {
            let containerView = UIView()
            
            let titleLabel = UILabel()
            titleLabel.text = "놀이기구"
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let collectionView = createRidesCollectionView()
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(titleLabel)
            containerView.addSubview(collectionView)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                
                collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
                collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                collectionView.heightAnchor.constraint(equalToConstant: 120),
                collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            return containerView
        }
        
        private func createRidesCollectionView() -> UICollectionView {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 100, height: 120)
            layout.minimumInteritemSpacing = 12
            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.backgroundColor = .clear
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.register(RideCell.self, forCellWithReuseIdentifier: "RideCell")
            collectionView.delegate = self
            collectionView.dataSource = self
            
            return collectionView
        }
        
        func prepareForReuse() {
            // 정리 작업
        }
    }

    extension PlaygroundDetailContent: UICollectionViewDelegate, UICollectionViewDataSource {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return playground.rides.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RideCell", for: indexPath) as! RideCell
            let ride = playground.rides[indexPath.item]
            cell.configure(with: ride)
            return cell
        }
    }

    // MARK: - RideCell
    class RideCell: UICollectionViewCell {
        private let iconImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .systemBlue
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        private let nameLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14)
            label.textAlignment = .center
            label.numberOfLines = 2
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI() {
            backgroundColor = .systemGray6
            layer.cornerRadius = 12
            
            contentView.addSubview(iconImageView)
            contentView.addSubview(nameLabel)
            
            NSLayoutConstraint.activate([
                iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 40),
                iconImageView.heightAnchor.constraint(equalToConstant: 40),
                
                nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
                nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
            ])
        }
        
        func configure(with ride: Ride) {
            nameLabel.text = ride.rideNm
            iconImageView.image = UIImage(systemName: "figure.play")
        }
    }

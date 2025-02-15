//
//  PlaygroundCell.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import UIKit
import RxSwift
import Kingfisher

class PlaygroundCell: UITableViewCell {
    static let identifier = "PlaygroundCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.backgroundColor = .systemGray6
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let photoGridView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var photoImageViews: [UIImageView] = []
    
    var disposeBag = DisposeBag()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(photoGridView)
        
        setupPhotoGrid()
        
        let gridWidthConstraint = photoGridView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -32)
        gridWidthConstraint.priority = .defaultHigh // 우선순위 조정
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            distanceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            distanceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            photoGridView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            photoGridView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            gridWidthConstraint,
            photoGridView.heightAnchor.constraint(equalToConstant: 114),
            photoGridView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupPhotoGrid() {
        // Clear existing image views
        photoImageViews.forEach { $0.removeFromSuperview() }
        photoImageViews.removeAll()
        
        let spacing: CGFloat = 1
        let imageCount = 3
        
        for i in 0..<imageCount {
            let imageView = UIImageView()
            imageView.contentMode = .scaleToFill
            imageView.clipsToBounds = true
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
            imageView.backgroundColor = .systemGray6
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            photoGridView.addSubview(imageView)
            photoImageViews.append(imageView)
            
            // Layout constraints
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: photoGridView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: photoGridView.bottomAnchor),
                imageView.widthAnchor.constraint(equalTo: photoGridView.widthAnchor, multiplier: 1.0/3.0, constant: -spacing * 2/3),
                imageView.leadingAnchor.constraint(equalTo: i == 0 ? photoGridView.leadingAnchor : photoImageViews[i-1].trailingAnchor, constant: spacing)
            ])
        }
    }
    
    // MARK: - Configuration
    func configure(with playground: Playground1, distance: Double?) {
        nameLabel.text = playground.pfctNm
        
        if let distance = distance {
            let distanceText = String(format: "%.1fkm", distance)
            distanceLabel.text = "\(distanceText) · 게시물 \(playground.reviews.count)"
        } else {
            distanceLabel.text = "거리 정보 없음 · 게시물 \(playground.reviews.count)"
        }
        
        // 리뷰 이미지 로드
        loadReviewImages(for: playground)
    }
    
    private func loadReviewImages(for playground: Playground1) {
        // 최근 3개의 리뷰 이미지만 표시
        let recentImageUrls = playground.reviews
            .flatMap { $0.imageUrls }
            .prefix(3)
        
        // 기본 이미지로 초기화
        photoImageViews.forEach { imageView in
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
        }
        
        // Kingfisher를 사용한 이미지 로드
        for (index, urlString) in recentImageUrls.enumerated() {
            guard index < photoImageViews.count,
                  let url = URL(string: urlString) else { continue }
            
            photoImageViews[index].kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        distanceLabel.text = nil
        photoImageViews.forEach { imageView in
            imageView.kf.cancelDownloadTask() // Kingfisher 다운로드 작업 취소
            imageView.image = UIImage(systemName: "photo")
        }
        disposeBag = DisposeBag()
    }
}

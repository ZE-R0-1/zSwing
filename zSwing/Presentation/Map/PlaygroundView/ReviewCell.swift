//
//  ReviewCell.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import UIKit
import Kingfisher

final class ReviewCell: UICollectionViewCell {
    static let identifier = "ReviewCell"
    
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let imageCountLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black.withAlphaComponent(0.6)
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.addSubview(imageCountLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageCountLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -4),
            imageCountLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4),
            imageCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            imageCountLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - Configuration
    func configure(with review: Review) {
        if let firstImageUrl = review.imageUrls.first,
           let url = URL(string: firstImageUrl) {
            // Kingfisher를 사용한 이미지 로딩
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage,
                    .cacheMemoryOnly
                ],
                completionHandler: { [weak self] result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        print("❌ Failed to load image: \(error.localizedDescription)")
                        self?.imageView.image = UIImage(systemName: "photo")
                        self?.imageView.tintColor = .systemGray4
                    }
                }
            )
            
            // 이미지가 2장 이상인 경우에만 카운트 표시
            let additionalCount = review.imageUrls.count - 1
            if additionalCount > 0 {
                imageCountLabel.isHidden = false
                imageCountLabel.text = "+\(additionalCount)"
                
                // 레이블 너비 동적 조정
                let width = additionalCount < 10 ? 20 : 26
                imageCountLabel.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
            } else {
                imageCountLabel.isHidden = true
            }
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
            imageCountLabel.isHidden = true
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        // Kingfisher 이미지 다운로드 취소
        imageView.kf.cancelDownloadTask()
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray4
        imageCountLabel.isHidden = true
        imageCountLabel.text = nil
    }
}

//
//  ReviewCell.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import UIKit

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
        if let firstImageUrl = review.imageUrls.first {
            loadImage(from: firstImageUrl)
            
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
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL string:", urlString)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading image:", error.localizedDescription)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to create image from data")
                return
            }
            
            DispatchQueue.main.async {
                print("Successfully loaded image")
                self?.imageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(systemName: "photo")
        imageCountLabel.isHidden = true
        imageCountLabel.text = nil
    }
}

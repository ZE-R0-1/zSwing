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
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemGray6 // 이미지 로딩 전 배경색
        return imageView
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
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with review: Review) {
        print("Configuring ReviewCell with review:", review)
        if let firstImageUrl = review.imageUrls.first {
            print("Loading image from URL:", firstImageUrl)
            loadImage(from: firstImageUrl)
        } else {
            print("No image URLs available for review")
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray4
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
    }
}

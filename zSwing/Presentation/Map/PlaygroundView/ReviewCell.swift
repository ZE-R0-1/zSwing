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
    func configure(with review: PlaygroundReview) {
        // TODO: 이미지 로딩 로직 구현
        // Firebase Storage나 다른 이미지 소스에서 이미지를 로드
        if let url = URL(string: review.imageUrl) {
            // URLSession을 사용한 기본적인 이미지 로딩
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

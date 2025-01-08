//
//  ReviewImageCell.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import UIKit

class ReviewImageCell: UICollectionViewCell {
    static let identifier = "ReviewImageCell"
    
    // MARK: - Properties
    var deleteHandler: (() -> Void)?
    
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.layer.borderWidth = 1  // 테두리 두께
        imageView.layer.borderColor = UIColor.systemGray4.cgColor  // 테두리 색상
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemRed
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 20),
            deleteButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func deleteButtonTapped() {
        deleteHandler?()
    }
    
    // MARK: - Configuration
    func configure(with image: UIImage) {
        imageView.image = image
        
        // 기본 이미지인 경우 스타일 조정
        if image.size == UIImage(systemName: "photo.fill")?.size {
            imageView.contentMode = .center
            imageView.tintColor = .systemGray3
            deleteButton.isHidden = true  // 기본 이미지에서는 삭제 버튼 숨김
        } else {
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = nil
            deleteButton.isHidden = false
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        deleteHandler = nil
    }
}

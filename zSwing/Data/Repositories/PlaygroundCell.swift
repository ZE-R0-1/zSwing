//
//  PlaygroundCell.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import UIKit

class PlaygroundCell: UITableViewCell {
    static let identifier = "PlaygroundCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .systemGray6
        imageView.image = UIImage(systemName: "figure.play")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let photoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(photoStackView)
        
        // 기본 이미지 3개 추가
        for _ in 0..<3 {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.backgroundColor = .systemGray6
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
            photoStackView.addArrangedSubview(imageView)
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 50),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            distanceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            distanceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            distanceLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            photoStackView.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 12),
            photoStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            photoStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            photoStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            photoStackView.heightAnchor.constraint(equalTo: photoStackView.widthAnchor, multiplier: 0.3)
        ])
    }
    
    // MARK: - Configuration
    func configure(with playground: Playground, distance: Double?) {
        nameLabel.text = playground.pfcfNm
        if let distance = distance {
            distanceLabel.text = String(format: "%.1fkm", distance)
        } else {
            distanceLabel.text = "거리 정보 없음"
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        distanceLabel.text = nil
        // Reset images to placeholder
        photoStackView.arrangedSubviews.forEach { view in
            if let imageView = view as? UIImageView {
                imageView.image = UIImage(systemName: "photo")
            }
        }
    }
}

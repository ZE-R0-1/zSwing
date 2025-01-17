//
//  FacilityCell.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit

class FacilityCell: UICollectionViewCell {
    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true  // 텍스트가 너무 길 경우 자동으로 폰트 크기 조정
        label.minimumScaleFactor = 0.8  // 폰트 크기를 최대 80%까지만 축소
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            // Icon container constraints
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            iconContainer.heightAnchor.constraint(equalTo: iconContainer.widthAnchor),
            
            // Icon image constraints
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: iconContainer.widthAnchor, multiplier: 0.5),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),
            
            // Name label constraints
            nameLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }
    
    private func setupStyle() {
        contentView.backgroundColor = .clear
        
        // 선택 시 효과를 위한 설정
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = .systemGray5
    }

    func configure(with facility: PlaygroundFacility) {
        iconImageView.image = UIImage(systemName: facility.imageName)
        nameLabel.text = facility.name
        
        if facility.name.count <= 5 {
            nameLabel.lineBreakMode = .byClipping  // 5글자 이하는 잘리지 않게
        } else {
            nameLabel.lineBreakMode = .byTruncatingTail  // 5글자 초과는 ...으로 표시
        }
    }
}

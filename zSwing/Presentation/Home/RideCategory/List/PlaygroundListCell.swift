//
//  PlaygroundListCell.swift
//  zSwing
//
//  Created by USER on 1/20/25.
//

import UIKit
import CoreLocation

final class PlaygroundListCell: UITableViewCell {
    static let identifier = "PlaygroundListCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = HomeViewModel.themeColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let facilitiesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
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
        contentView.addSubview(containerView)
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(addressLabel)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(facilitiesStackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: distanceLabel.leadingAnchor, constant: -8),
            
            distanceLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            addressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            facilitiesStackView.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 12),
            facilitiesStackView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            facilitiesStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with playground: Playground, distance: CLLocationDistance) {
        nameLabel.text = playground.name
        addressLabel.text = playground.address
        distanceLabel.text = formatDistance(distance)
        
        // 기존 시설 아이콘들 제거
        facilitiesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 시설 아이콘들 추가
        playground.facilities.forEach { facility in
            let iconView = createFacilityIconView(with: facility)
            facilitiesStackView.addArrangedSubview(iconView)
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return String(format: "%.0fm", distance)
        }
    }
    
    private func createFacilityIconView(with facility: PlaygroundFacility) -> UIView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = .systemGray6
        iconContainer.layer.cornerRadius = 8
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: facility.imageName)
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        iconContainer.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 32),
            iconContainer.heightAnchor.constraint(equalToConstant: 32),
            
            imageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return iconContainer
    }
}

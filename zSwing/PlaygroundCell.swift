//
//  PlaygroundCell.swift
//  zSwing
//
//  Created by USER on 11/4/24.
//

import UIKit

class PlaygroundCell: UITableViewCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(distanceLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: distanceLabel.leadingAnchor, constant: -8),
            
            distanceLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            distanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contentView.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12)
        ])
    }
    
    func configure(with item: PlaygroundItem) {
        nameLabel.text = item.facilityName
        distanceLabel.text = item.distanceText
    }
}

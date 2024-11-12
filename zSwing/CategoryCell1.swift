////
////  CategoryCell.swift
////  zSwing
////
////  Created by USER on 11/4/24.
////
//
//import UIKit
//
//class CategoryCell: UICollectionViewCell {
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupUI() {
//        contentView.backgroundColor = .systemGray6
//        contentView.layer.cornerRadius = 18
//        
//        contentView.addSubview(titleLabel)
//        NSLayoutConstraint.activate([
//            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
//        ])
//    }
//    
//    func configure(with title: String, isSelected: Bool) {
//        titleLabel.text = title
//        contentView.backgroundColor = isSelected ? .systemBlue : .systemGray6
//        titleLabel.textColor = isSelected ? .white : .black
//    }
//}

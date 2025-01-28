//
//  PlaygroundDetailView.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import UIKit
import RxSwift

class PlaygroundDetailView: UIView {
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let addressContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = HomeViewModel.themeColor
        return label
    }()
    
    private let facilitiesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.text = "시설물"
        return label
    }()
    
    private let facilitiesScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let facilitiesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
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
        backgroundColor = .systemBackground
        
        addSubview(stackView)
        
        stackView.addArrangedSubview(nameLabel)
        
        addressContainer.addArrangedSubview(addressLabel)
        addressContainer.addArrangedSubview(distanceLabel)
        stackView.addArrangedSubview(addressContainer)
        
        stackView.addArrangedSubview(facilitiesLabel)
        
        facilitiesScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(facilitiesScrollView)
        facilitiesScrollView.addSubview(facilitiesStackView)
        facilitiesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20),
            
            facilitiesStackView.leadingAnchor.constraint(equalTo: facilitiesScrollView.leadingAnchor),
            facilitiesStackView.trailingAnchor.constraint(equalTo: facilitiesScrollView.trailingAnchor),
            facilitiesStackView.topAnchor.constraint(equalTo: facilitiesScrollView.topAnchor),
            facilitiesStackView.bottomAnchor.constraint(equalTo: facilitiesScrollView.bottomAnchor),
            facilitiesStackView.heightAnchor.constraint(equalTo: facilitiesScrollView.heightAnchor)
        ])
    }
    
    func configure(with viewModel: PlaygroundDetailViewModel) {
        nameLabel.text = viewModel.name
        addressLabel.text = viewModel.address
        distanceLabel.text = viewModel.distanceText
        dateLabel.text = "설치: \(viewModel.installationDate)"
        
        // 기존 시설물 아이콘 제거
        facilitiesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 시설물 아이콘 추가
        viewModel.facilities.forEach { facility in
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
            
            facilitiesStackView.addArrangedSubview(iconContainer)
        }
    }
}

//
//  RatingView.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import UIKit
import RxSwift
import RxCocoa

class RatingView: UIView {
    // MARK: - Properties
    private let stackView = UIStackView()
    private var starButtons: [UIButton] = []
    private let maxRating = 5
    
    let ratingChanged = PublishRelay<Double>()
    private var currentRating: Double = 0
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupStackView()
        createStarButtons()
    }
    
    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func createStarButtons() {
        for i in 0..<maxRating {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "star"), for: .normal)
            button.setImage(UIImage(systemName: "star.fill"), for: .selected)
            button.tintColor = .systemYellow
            button.tag = i + 1
            button.addTarget(self, action: #selector(starButtonTapped(_:)), for: .touchUpInside)
            
            // 버튼 크기 설정
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            
            starButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - Action Handlers
    @objc private func starButtonTapped(_ sender: UIButton) {
        let rating = Double(sender.tag)
        updateRating(rating)
        ratingChanged.accept(rating)
    }
    
    // MARK: - Public Methods
    func updateRating(_ rating: Double) {
        currentRating = rating
        
        starButtons.enumerated().forEach { index, button in
            let buttonRating = Double(index + 1)
            button.isSelected = buttonRating <= rating
        }
    }
    
    func getRating() -> Double {
        return currentRating
    }
}

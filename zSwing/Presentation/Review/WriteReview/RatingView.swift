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
            let button = UIButton()
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            
            let normalImage = UIImage(systemName: "star", withConfiguration: config)?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            let halfImage = UIImage(systemName: "star.leadinghalf.filled", withConfiguration: config)?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            let selectedImage = UIImage(systemName: "star.fill", withConfiguration: config)?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            
            button.setImage(normalImage, for: .normal)
            button.setImage(selectedImage, for: .selected)
            button.tag = i + 1
            button.backgroundColor = .clear
            
            // 제스처 인식기 추가
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(starTapped(_:)))
            button.addGestureRecognizer(tapGesture)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            
            starButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - Action Handlers
    @objc private func starTapped(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        let location = gesture.location(in: button)
        let buttonWidth = button.bounds.width
        let tag = button.tag
        
        // 터치 위치가 버튼의 왼쪽 절반에 있는지 오른쪽 절반에 있는지 확인
        let rating = location.x <= buttonWidth/2 ? Double(tag) - 0.5 : Double(tag)
        updateRating(rating)
        ratingChanged.accept(rating)
    }
    
    // MARK: - Public Methods
    func updateRating(_ rating: Double) {
        currentRating = rating
        
        starButtons.enumerated().forEach { index, button in
            let buttonNumber = index + 1
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            
            if Double(buttonNumber) <= rating {
                // 전체 별
                let fullStar = UIImage(systemName: "star.fill", withConfiguration: config)?
                    .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
                button.setImage(fullStar, for: .normal)
            } else if Double(buttonNumber) - 0.5 == rating {
                // 반 별
                let halfStar = UIImage(systemName: "star.leadinghalf.filled", withConfiguration: config)?
                    .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
                button.setImage(halfStar, for: .normal)
            } else {
                // 빈 별
                let emptyStar = UIImage(systemName: "star", withConfiguration: config)?
                    .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
                button.setImage(emptyStar, for: .normal)
            }
        }
    }
    
    func getRating() -> Double {
        return currentRating
    }}

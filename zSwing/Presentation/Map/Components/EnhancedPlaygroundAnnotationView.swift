//
//  EnhancedPlaygroundAnnotationView.swift
//  zSwing
//
//  Created by USER on 11/19/24.
//

import UIKit
import MapKit

class EnhancedPlaygroundAnnotationView: MKAnnotationView {
    static let identifier = "EnhancedPlaygroundAnnotationView"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.clipsToBounds = true
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.image = UIImage(systemName: "figure.play")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    // MARK: - Properties
    private var animator: UIViewPropertyAnimator?
    private let markerSize: CGFloat = 30
    private let titleHeight: CGFloat = 16
    private let maxLabelWidth: CGFloat = 80
    
    // MARK: - Initialization
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        canShowCallout = false
        
        // 전체 프레임 설정
        let totalHeight = markerSize + titleHeight + 4
        frame = CGRect(x: 0, y: 0, width: maxLabelWidth, height: totalHeight)
        centerOffset = CGPoint(x: 0, y: -markerSize/2)
        
        // 컨테이너 뷰 설정
        addSubview(containerView)
        containerView.frame = CGRect(
            x: (maxLabelWidth - markerSize) / 2,
            y: 0,
            width: markerSize,
            height: markerSize
        )
        containerView.layer.cornerRadius = markerSize/2
        
        // 아이콘 이미지뷰 설정
        containerView.addSubview(iconImageView)
        iconImageView.frame = containerView.bounds.insetBy(dx: 6, dy: 6)
        
        // 제목 레이블 설정
        addSubview(titleLabel)
        titleLabel.frame = CGRect(
            x: 0,
            y: markerSize + 4,
            width: maxLabelWidth,
            height: titleHeight
        )
        
        // 그림자 설정
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.2
    }
    
    // MARK: - Configuration
    func configure(with annotation: PlaygroundAnnotation) {
        titleLabel.text = annotation.playground.pfctNm
    }
    
    // MARK: - Animation
    func animateSelection(selected: Bool) {
        // 이전 애니메이션 취소
        animator?.stopAnimation(true)
        
        // 새 애니메이션 시작
        animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.7) {
            if selected {
                self.containerView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.containerView.backgroundColor = .systemBlue
                self.iconImageView.tintColor = .white
                self.titleLabel.textColor = .systemBlue
                self.containerView.layer.shadowOpacity = 0.4
                self.containerView.layer.shadowRadius = 6
            } else {
                self.containerView.transform = .identity
                self.containerView.backgroundColor = .white
                self.iconImageView.tintColor = .systemBlue
                self.titleLabel.textColor = .darkGray
                self.containerView.layer.shadowOpacity = 0.2
                self.containerView.layer.shadowRadius = 4
            }
        }
        
        animator?.startAnimation()
    }
    
    // MARK: - Override Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        animator?.stopAnimation(true)
        containerView.transform = .identity
        containerView.backgroundColor = .white
        iconImageView.tintColor = .systemBlue
        titleLabel.textColor = .darkGray
        titleLabel.text = nil
    }
}

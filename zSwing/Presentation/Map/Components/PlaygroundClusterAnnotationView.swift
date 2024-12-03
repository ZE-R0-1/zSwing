//
//  EnhancedPlaygroundClusterAnnotationView.swift
//  zSwing
//
//  Created by USER on 11/19/24.
//

import UIKit
import MapKit

class PlaygroundClusterAnnotationView: MKAnnotationView {
    static let identifier = "EnhancedPlaygroundClusterAnnotationView"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let backgroundCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.image = UIImage(systemName: "figure.play")
        return imageView
    }()
    
    // MARK: - Properties
    private var animator: UIViewPropertyAnimator?
    private var playgrounds: [Playground] = []
    
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
        // 기본 설정
        backgroundColor = .clear
        canShowCallout = false
        
        // 서브뷰 추가
        addSubview(containerView)
        containerView.addSubview(backgroundCircleView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(countLabel)
    }
    
    // MARK: - Configuration
    func configure(with cluster: MKClusterAnnotation) {
        let count = cluster.memberAnnotations.count
        
        // 클러스터 크기에 따른 동적 크기 조절
        let size = calculateSize(for: count)
        let fontSize = calculateFontSize(for: count)
        
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -size/2)
        
        containerView.frame = bounds
        backgroundCircleView.frame = bounds
        backgroundCircleView.layer.cornerRadius = size/2
        
        // 아이콘 크기 조절
        let iconSize = size * 0.5
        iconImageView.frame = CGRect(
            x: (size - iconSize)/2,
            y: (size - iconSize)/2,
            width: iconSize,
            height: iconSize
        )
        
        // 카운트 레이블 설정
        countLabel.font = .systemFont(ofSize: fontSize, weight: .bold)
        countLabel.frame = CGRect(
            x: size * 0.6,
            y: 0,
            width: size * 0.4,
            height: size * 0.4
        )
        countLabel.text = "\(count)"
        
        // 그림자 효과
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.2
        
        // 클러스터에 포함된 놀이터 저장
        playgrounds = cluster.memberAnnotations.compactMap { annotation in
            (annotation as? PlaygroundAnnotation)?.playground
        }
        
        // 클러스터 색상 설정
        updateClusterAppearance(count: count)
    }
    
    // MARK: - Helper Methods
    private func calculateSize(for count: Int) -> CGFloat {
        // 클러스터 크기에 따른 동적 크기 계산
        let baseSize: CGFloat = 40
        let maxSize: CGFloat = 60
        let sizeIncrement = min(CGFloat(count) / 50.0, 1.0) // 최대 50개까지 크기 증가
        return baseSize + (maxSize - baseSize) * sizeIncrement
    }
    
    private func calculateFontSize(for count: Int) -> CGFloat {
        // 숫자 길이에 따른 폰트 크기 조절
        let digits = String(count).count
        let baseSize: CGFloat = 13
        return baseSize - CGFloat(max(0, digits - 2)) * 2
    }
    
    private func updateClusterAppearance(count: Int) {
        // 클러스터 크기에 따른 색상 변화
        let color: UIColor
        switch count {
        case 0...10:
            color = .systemBlue
        case 11...30:
            color = .systemGreen
        case 31...50:
            color = .systemOrange
        default:
            color = .systemRed
        }
        
        backgroundCircleView.backgroundColor = color.withAlphaComponent(0.85)
    }
    
    // MARK: - Animation
    func animateSelection(selected: Bool) {
        // 이전 애니메이션 취소
        animator?.stopAnimation(true)
        
        // 새 애니메이션 시작
        animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.7) {
            if selected {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.backgroundCircleView.backgroundColor = self.backgroundCircleView.backgroundColor?.withAlphaComponent(1.0)
                self.layer.shadowOpacity = 0.4
                self.layer.shadowRadius = 6
            } else {
                self.transform = .identity
                self.backgroundCircleView.backgroundColor = self.backgroundCircleView.backgroundColor?.withAlphaComponent(0.85)
                self.layer.shadowOpacity = 0.2
                self.layer.shadowRadius = 4
            }
        }
        
        animator?.startAnimation()
    }
    
    // MARK: - Interaction Helpers
    func getPlaygrounds() -> [Playground] {
        return playgrounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        animator?.stopAnimation(true)
        transform = .identity
        playgrounds.removeAll()
    }
}

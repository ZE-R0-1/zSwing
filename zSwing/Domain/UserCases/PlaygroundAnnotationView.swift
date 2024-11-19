//
//  PlaygroundAnnotationView.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import UIKit
import MapKit

class PlaygroundAnnotationView: MKAnnotationView {
    static let identifier = "PlaygroundAnnotationView"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.2
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
    private let titleHeight: CGFloat = 16
    private let markerSize: CGFloat = 30
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
        // 전체 프레임 설정
        let totalHeight = markerSize + titleHeight + 4
        frame = CGRect(x: 0, y: 0, width: maxLabelWidth, height: totalHeight)
        
        // 중심점을 마커의 중앙으로 설정
        centerOffset = CGPoint(x: 0, y: -markerSize/2)
        
        canShowCallout = false
        
        // 컨테이너 뷰 설정
        containerView.frame = CGRect(
            x: (maxLabelWidth - markerSize) / 2, // 중앙 정렬
            y: 0,
            width: markerSize,
            height: markerSize
        )
        addSubview(containerView)
        
        // 아이콘 이미지뷰 설정
        iconImageView.frame = containerView.bounds.insetBy(dx: 6, dy: 6)
        containerView.addSubview(iconImageView)
        
        // 제목 레이블 설정
        titleLabel.frame = CGRect(
            x: 0,
            y: markerSize + 4,
            width: maxLabelWidth,
            height: titleHeight
        )
        addSubview(titleLabel)
        
        // 기본 스타일 적용
        applyStyle(selected: false)
    }
    
    // MARK: - Style & Animation
    private func applyStyle(selected: Bool) {
        let backgroundColor: UIColor = selected ? .systemBlue : .white
        let tintColor: UIColor = selected ? .white : .systemBlue
        let shadowOpacity: Float = selected ? 0.4 : 0.2
        let shadowRadius: CGFloat = selected ? 6 : 4
        let textColor: UIColor = selected ? .systemBlue : .darkGray
        
        // 마커 스타일 적용
        containerView.backgroundColor = backgroundColor
        iconImageView.tintColor = tintColor
        containerView.layer.shadowOpacity = shadowOpacity
        containerView.layer.shadowRadius = shadowRadius
        
        // 레이블 스타일 적용
        titleLabel.textColor = textColor
    }
    
    func animateSelection(selected: Bool) {
        UIView.animate(withDuration: 0.3,
                      delay: 0,
                      usingSpringWithDamping: 0.7,
                      initialSpringVelocity: 0.5,
                      options: .curveEaseInOut) {
            // 마커만 크기 변경
            self.containerView.transform = selected ?
                CGAffineTransform(scaleX: 1.2, y: 1.2) :
                .identity
            self.applyStyle(selected: selected)
        }
    }
    
    // MARK: - Override Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.transform = .identity
        applyStyle(selected: false)
        titleLabel.text = nil
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        if let annotation = annotation as? PlaygroundAnnotation {
            titleLabel.text = annotation.playground.pfctNm
        }
        applyStyle(selected: isSelected)
    }
}

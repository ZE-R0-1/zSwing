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
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 30 // bubbleSize / 2
        view.layer.masksToBounds = true
        // Instagram 스타일의 흰색 테두리
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        return view
    }()
    
    private let triangleView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemBackground
        
        // 기본 이미지 설정
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "photo.fill", withConfiguration: config)
        imageView.image = image
        imageView.tintColor = .systemGray3
        
        return imageView
    }()
    
    override var annotation: MKAnnotation? {
        didSet {
            updateUI()
        }
    }
    
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
        let bubbleSize: CGFloat = 60
        let triangleHeight: CGFloat = 7
        
        // 전체 프레임을 동그라미 크기로만 설정
        frame = CGRect(x: 0, y: 0, width: bubbleSize, height: bubbleSize)
        backgroundColor = .clear
        
        // 컨테이너 뷰 설정
        addSubview(containerView)
        containerView.frame = CGRect(x: 0, y: 0, width: bubbleSize, height: bubbleSize)
        
        // 이미지 뷰 설정
        containerView.addSubview(imageView)
        imageView.frame = containerView.bounds
        
        // 삼각형 꼬리 추가
        addSubview(triangleView)
        // 삼각형 위치를 정확히 동그라미 아래로 설정
        triangleView.frame = CGRect(x: 0, y: bubbleSize, width: bubbleSize, height: triangleHeight)
        
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: bubbleSize / 2 - 10, y: 0))
        trianglePath.addLine(to: CGPoint(x: bubbleSize / 2 + 10, y: 0))
        trianglePath.addLine(to: CGPoint(x: bubbleSize / 2, y: triangleHeight))
        trianglePath.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = trianglePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        triangleView.layer.addSublayer(shapeLayer)
        
        // 그림자 설정
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.3
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: containerView.layer.cornerRadius).cgPath
        
        // 말풍선 제거
        canShowCallout = false
        
        // 중심점 조정 (삼각형 끝이 핀 위치에 오도록)
        centerOffset = CGPoint(x: 0, y: -bubbleSize)
    }

    
    private func updateUI() {
        // 향후 실제 이미지 업데이트를 위한 공간
    }
    
    // MARK: - Animation
    func animateSelection(selected: Bool) {
        let scale: CGFloat = selected ? 1.3 : 1.0
        let duration: TimeInterval = 0.3
        let offsetY = (selected ? 1.3 : 1.0) * (frame.size.height / 2)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseInOut, .allowUserInteraction]) {
            // 확대/축소 애니메이션
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // 확대/축소 시 중심 위치 보정
            self.centerOffset = CGPoint(x: 0, y: -offsetY)
            
            // 테두리 굵기 변경
            self.containerView.layer.borderWidth = selected ? 4 : 3
            
            // 그림자 변경
            self.layer.shadowOpacity = selected ? 0.4 : 0.3
            self.layer.shadowRadius = selected ? 8 : 6
        }
    }

}

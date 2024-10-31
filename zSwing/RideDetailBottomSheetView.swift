//
//  RideDetailBottomSheetView.swift
//  zSwing
//
//  Created by USER on 10/29/24.
//

import UIKit

class RideDetailBottomSheetView: UIView {
    // MARK: - Properties
    private let dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var initialTouchPoint: CGPoint = .zero
    private var currentHeight: CGFloat = 0
    
    // Height states
    private let defaultHeight: CGFloat = UIScreen.main.bounds.height * 0.4  // 40%
    private let maximumHeight: CGFloat = UIScreen.main.bounds.height * 0.9  // 90%
    private let minimumHeight: CGFloat = UIScreen.main.bounds.height * 0.2  // 20%
    
    var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGestures()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        
        // Add Drag Indicator
        addSubview(dragIndicator)
        NSLayoutConstraint.activate([
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 5),
            dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        ])
        
        // Add Info Stack View
        addSubview(infoStackView)
        NSLayoutConstraint.activate([
            infoStackView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - Gesture Handling
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: self.superview)
            currentHeight = frame.height
            
        case .changed:
            let newHeight = currentHeight - translation.y
            updateHeight(newHeight)
            
        case .ended:
            let projectedHeight = currentHeight - translation.y - velocity.y * 0.2
            
            // Determine final height based on velocity and projected position
            if velocity.y > 1000 {
                // Fast downward swipe
                animateHeight(to: minimumHeight)
            } else if velocity.y < -1000 {
                // Fast upward swipe
                animateHeight(to: maximumHeight)
            } else if projectedHeight < (defaultHeight + minimumHeight) / 2 {
                // Below middle of minimum and default
                animateHeight(to: minimumHeight)
            } else if projectedHeight > (defaultHeight + maximumHeight) / 2 {
                // Above middle of default and maximum
                animateHeight(to: maximumHeight)
            } else {
                // Return to default height
                animateHeight(to: defaultHeight)
            }
            
        default:
            break
        }
    }
    
    private func updateHeight(_ height: CGFloat) {
        let newHeight = min(max(height, minimumHeight), maximumHeight)
        heightConstraint?.constant = newHeight
        
        // 맵뷰의 마진 업데이트를 위해 delegate 호출
        if let mapVC = superview?.next as? MapViewController {
            mapVC.updateMapLayoutMargins(bottomInset: newHeight)
        }
        
        superview?.layoutIfNeeded()
    }
    
    private func animateHeight(to height: CGFloat) {
        UIView.animate(withDuration: 0.3,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 0.5,
                      options: .curveEaseOut,
                      animations: { [weak self] in
            self?.heightConstraint?.constant = height
            
            // 맵뷰의 마진 업데이트를 위해 delegate 호출
            if let mapVC = self?.superview?.next as? MapViewController {
                mapVC.updateMapLayoutMargins(bottomInset: height)
            }
            
            self?.superview?.layoutIfNeeded()
        })
    }

    
    // MARK: - Public Methods
    func showRideDetail(for rideInfo: RideInfo) {
        // Clear previous info
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new info
        let nameLabel = createLabel(text: rideInfo.rideName, font: .boldSystemFont(ofSize: 24))
        let facilityLabel = createLabel(text: rideInfo.facilityName, font: .systemFont(ofSize: 18), textColor: .gray)
        let addressLabel = createLabel(text: rideInfo.address, font: .systemFont(ofSize: 16))
        addressLabel.numberOfLines = 0
        
        let separator = createSeparator()
        
        let typeLabel = createLabel(text: "놀이기구 유형: \(rideInfo.rideType)", font: .systemFont(ofSize: 16))
        let dateLabel = createLabel(text: "설치일: \(rideInfo.installDate)", font: .systemFont(ofSize: 16))
        
        [nameLabel, facilityLabel, separator, addressLabel, typeLabel, dateLabel].forEach {
            infoStackView.addArrangedSubview($0)
        }
        
        // Show with animation
        isHidden = false
        heightConstraint?.constant = 0
        
        // 시작할 때 맵뷰의 마진을 0으로 설정
        if let mapVC = superview?.next as? MapViewController {
            mapVC.updateMapLayoutMargins(bottomInset: 0)
        }
        
        superview?.layoutIfNeeded()  // 초기 상태 적용
        
        UIView.animate(withDuration: 0.5,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 0.5,
                      options: .curveEaseOut,
                      animations: { [weak self] in
            guard let self = self else { return }
            self.heightConstraint?.constant = self.defaultHeight
            
            // 애니메이션과 함께 맵뷰의 마진도 업데이트
            if let mapVC = self.superview?.next as? MapViewController {
                mapVC.updateMapLayoutMargins(bottomInset: self.defaultHeight)
            }
            
            self.superview?.layoutIfNeeded()
        })
    }
    // MARK: - Private Methods
    private func createLabel(text: String, font: UIFont, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
}

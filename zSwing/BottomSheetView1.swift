////
////  BottomSheetView.swift
////  zSwing
////
////  Created by USER on 11/5/24.
////
//
//import UIKit
//
//class BottomSheetView: UIView {
//    // MARK: - Public Properties
//    var defaultHeight: CGFloat = UIScreen.main.bounds.height * 0.4
//    var maximumHeight: CGFloat = UIScreen.main.bounds.height * 0.9
//    var minimumHeight: CGFloat = UIScreen.main.bounds.height * 0.2
//    var heightConstraint: NSLayoutConstraint?
//    var onHeightChanged: ((CGFloat) -> Void)?
//    
//    // MARK: - Private Properties
//    private let dragIndicator: UIView = {
//        let view = UIView()
//        view.backgroundColor = .systemGray3
//        view.layer.cornerRadius = 2.5
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let contentView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private var initialTouchPoint: CGPoint = .zero
//    private var currentHeight: CGFloat = 0
//    
//    // MARK: - Initialization
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupUI()
//    }
//    
//    // MARK: - Setup Methods
//    private func setupUI() {
//        backgroundColor = .white
//        layer.cornerRadius = 20
//        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOffset = CGSize(width: 0, height: -3)
//        layer.shadowRadius = 3
//        layer.shadowOpacity = 0.1
//        translatesAutoresizingMaskIntoConstraints = false
//        
//        setupDragIndicator()
//        setupContentView()
//        setupGestures()
//    }
//    
//    private func setupDragIndicator() {
//        addSubview(dragIndicator)
//        NSLayoutConstraint.activate([
//            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
//            dragIndicator.heightAnchor.constraint(equalToConstant: 5),
//            dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
//            dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12)
//        ])
//    }
//    
//    private func setupContentView() {
//        addSubview(contentView)
//        NSLayoutConstraint.activate([
//            contentView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 20),
//            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//    }
//    
//    private func setupGestures() {
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
//        addGestureRecognizer(panGesture)
//    }
//    
//    // MARK: - Gesture Handling
//    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: self.superview)
//        let velocity = gesture.velocity(in: self.superview)
//        
//        switch gesture.state {
//        case .began:
//            initialTouchPoint = gesture.location(in: self.superview)
//            currentHeight = frame.height
//            
//        case .changed:
//            let newHeight = currentHeight - translation.y
//            updateHeight(newHeight)
//            
//        case .ended:
//            let projectedHeight = currentHeight - translation.y - velocity.y * 0.2
//            
//            if velocity.y > 1000 {
//                animateHeight(to: minimumHeight)
//            } else if velocity.y < -1000 {
//                animateHeight(to: maximumHeight)
//            } else if projectedHeight < (defaultHeight + minimumHeight) / 2 {
//                animateHeight(to: minimumHeight)
//            } else if projectedHeight > (defaultHeight + maximumHeight) / 2 {
//                animateHeight(to: maximumHeight)
//            } else {
//                animateHeight(to: defaultHeight)
//            }
//            
//        default:
//            break
//        }
//    }
//    
//    // MARK: - Public Methods
//    func setContent(_ view: UIView) {
//        contentView.subviews.forEach { $0.removeFromSuperview() }
//        contentView.addSubview(view)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            view.topAnchor.constraint(equalTo: contentView.topAnchor),
//            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        ])
//    }
//    
//    func updateHeight(_ height: CGFloat) {
//        let newHeight = min(max(height, minimumHeight), maximumHeight)
//        heightConstraint?.constant = newHeight
//        onHeightChanged?(newHeight)
//        superview?.layoutIfNeeded()
//    }
//    
//    func animateHeight(to height: CGFloat) {
//        UIView.animate(
//            withDuration: 0.3,
//            delay: 0,
//            usingSpringWithDamping: 0.8,
//            initialSpringVelocity: 0.5,
//            options: .curveEaseOut,
//            animations: { [weak self] in
//                self?.heightConstraint?.constant = height
//                self?.onHeightChanged?(height)
//                self?.superview?.layoutIfNeeded()
//            }
//        )
//    }
//}

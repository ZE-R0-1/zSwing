//
//  CustomBottomSheetView.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

class CustomBottomSheetView: UIView {
    // MARK: - Constants
    private enum Const {
        static let height: CGFloat = UIScreen.main.bounds.height * 0.6
        static let minHeight: CGFloat = 100
        static let cornerRadius: CGFloat = 20
        static let dragIndicatorSize = CGSize(width: 60, height: 4)
        static let dragIndicatorTopPadding: CGFloat = 12
    }
    
    // MARK: - UI Components
    private let dragIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var bottomConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    
    private var currentHeight: CGFloat = Const.height
    private var previousPanPoint: CGFloat = 0
    
    // MARK: - RxSwift Subjects
    let heightPercentage = BehaviorRelay<CGFloat>(value: 1.0)
    let isDismissed = PublishRelay<Bool>()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = Const.cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        
        addSubview(dragIndicatorView)
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            dragIndicatorView.topAnchor.constraint(equalTo: topAnchor, constant: Const.dragIndicatorTopPadding),
            dragIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            dragIndicatorView.widthAnchor.constraint(equalToConstant: Const.dragIndicatorSize.width),
            dragIndicatorView.heightAnchor.constraint(equalToConstant: Const.dragIndicatorSize.height),
            
            contentView.topAnchor.constraint(equalTo: dragIndicatorView.bottomAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        let panGesture = rx.panGesture()
        
        panGesture
            .when(.began, .changed, .ended)
            .subscribe(onNext: { [weak self] gesture in
                self?.handlePanGesture(gesture)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Gesture Handling
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self).y
        let velocity = gesture.velocity(in: self).y
        
        switch gesture.state {
        case .began:
            previousPanPoint = currentHeight
            
        case .changed:
            let newHeight = previousPanPoint - translation
            let heightPercentage = calculateHeightPercentage(newHeight)
            updateHeight(newHeight, animated: false)
            self.heightPercentage.accept(heightPercentage)
            
        case .ended, .cancelled:
            let projectedHeight = previousPanPoint - translation - (0.1 * velocity)
            let targetHeight: CGFloat
            
            if projectedHeight < Const.height * 0.3 {
                targetHeight = Const.minHeight
                isDismissed.accept(true)
            } else if projectedHeight < Const.height * 0.7 {
                targetHeight = Const.height * 0.5
            } else {
                targetHeight = Const.height
            }
            
            updateHeight(targetHeight, animated: true)
            heightPercentage.accept(calculateHeightPercentage(targetHeight))
            
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    private func updateHeight(_ height: CGFloat, animated: Bool) {
        let boundedHeight = max(Const.minHeight, min(height, Const.height))
        currentHeight = boundedHeight
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.heightConstraint?.constant = boundedHeight
                self.superview?.layoutIfNeeded()
            }
        } else {
            heightConstraint?.constant = boundedHeight
        }
    }
    
    private func calculateHeightPercentage(_ height: CGFloat) -> CGFloat {
        return (height - Const.minHeight) / (Const.height - Const.minHeight)
    }
    
    // MARK: - Public Methods
    func setHeight(_ height: CGFloat, animated: Bool) {
        updateHeight(height, animated: animated)
    }
    
    func addContentView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

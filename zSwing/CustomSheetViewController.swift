//
//  CustomSheetViewController.swift
//  zSwing
//
//  Created by USER on 10/28/24.
//

import UIKit

class CustomSheetViewController: UIViewController {
    // Constants for sheet behavior
    private enum Constants {
        static let mediumDetentHeight: CGFloat = UIScreen.main.bounds.height * 0.4
        static let largeDetentHeight: CGFloat = UIScreen.main.bounds.height * 0.9
        static let cornerRadius: CGFloat = 20.0
        static let grabberHeight: CGFloat = 5.0
        static let grabberWidth: CGFloat = 36.0
    }
    
    // MARK: - Properties
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let grabberView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = Constants.grabberHeight / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var containerViewHeightConstraint: NSLayoutConstraint?
    private var currentDetent: SheetDetent = .medium
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    // Customizable content
    private let contentViewController: UIViewController
    
    // MARK: - Initialization
    init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Add content view
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // Height constraint for animations
        containerViewHeightConstraint = contentView.heightConstraint(Constants.mediumDetentHeight)
        containerViewHeightConstraint?.isActive = true
        
        // Bottom constraint
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // Add grabber view
        contentView.addSubview(grabberView)
        NSLayoutConstraint.activate([
            grabberView.widthAnchor.constraint(equalToConstant: Constants.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: Constants.grabberHeight),
            grabberView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            grabberView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        // Add content view controller
        addChild(contentViewController)
        contentView.addSubview(contentViewController.view)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentViewController.view.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 8),
            contentViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        contentViewController.didMove(toParent: self)
        
        // Initial transform
        contentView.transform = CGAffineTransform(translationX: 0, y: Constants.mediumDetentHeight)
    }
    
    private func setupGestures() {
        // Pan gesture for sheet movement
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        contentView.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Animations
    private func animateIn() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.contentView.transform = .identity
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentView.frame.height)
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Gesture Handling
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            let newHeight = getCurrentDetentHeight() - translation.y
            containerViewHeightConstraint?.constant = min(max(newHeight, 0), Constants.largeDetentHeight)
            
        case .ended:
            let currentHeight = containerViewHeightConstraint?.constant ?? 0
            
            if abs(velocity.y) > 500 {
                if velocity.y > 0 {
                    if currentHeight > Constants.mediumDetentHeight {
                        animateToDetent(.medium)
                    } else {
                        dismissSheet()
                    }
                } else {
                    animateToDetent(.large)
                }
            } else {
                if currentHeight < Constants.mediumDetentHeight / 2 {
                    dismissSheet()
                } else if abs(currentHeight - Constants.mediumDetentHeight) < abs(currentHeight - Constants.largeDetentHeight) {
                    animateToDetent(.medium)
                } else {
                    animateToDetent(.large)
                }
            }
            
        default:
            break
        }
    }
    
    private func getCurrentDetentHeight() -> CGFloat {
        return currentDetent == .medium ? Constants.mediumDetentHeight : Constants.largeDetentHeight
    }
    
    private func animateToDetent(_ detent: SheetDetent) {
        let targetHeight = detent == .medium ? Constants.mediumDetentHeight : Constants.largeDetentHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.containerViewHeightConstraint?.constant = targetHeight
            self.view.layoutIfNeeded()
        }
        currentDetent = detent
    }
    
    private func dismissSheet() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }
}

// MARK: - Helper Types
enum SheetDetent {
    case medium
    case large
}

// MARK: - UIView Extension
extension UIView {
    func heightConstraint(_ constant: CGFloat) -> NSLayoutConstraint {
        return heightAnchor.constraint(equalToConstant: constant)
    }
}

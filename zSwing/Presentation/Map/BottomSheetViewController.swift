//
//  BottomSheetViewController.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import UIKit
import RxSwift
import RxCocoa

class BottomSheetViewController: UIViewController {
    // MARK: - Types
    
    enum SheetHeight {
        case min, mid, max
        
        var heightPercentage: CGFloat {
            switch self {
            case .min: return 0.1
            case .mid: return 0.465
            case .max: return 0.9
            }
        }
    }
    
    // MARK: - Properties
    private let bottomSheetHeight = BehaviorRelay<SheetHeight>(value: .mid)
    private let disposeBag = DisposeBag()
    private var panStartLocation: CGFloat = 0
    private var previousHeight: CGFloat = 0
    
    let contentView = UIView()
    private(set) var currentHeight: SheetHeight = .mid
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -3)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupGestures()
        bindHeight()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(containerView)
        containerView.addSubview(dragIndicator)
        containerView.addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        heightConstraint = containerView.heightAnchor.constraint(equalToConstant:
            UIScreen.main.bounds.height * SheetHeight.mid.heightPercentage)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint!,
            
            dragIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            dragIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 4),
            
            contentView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 12),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer()
        containerView.addGestureRecognizer(panGesture)
        
        panGesture.rx.event
            .bind { [weak self] gesture in
                self?.handlePanGesture(gesture)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindHeight() {
        bottomSheetHeight
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] height in
                self?.updateHeight(to: height)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Height Management
    
    private func updateHeight(to height: SheetHeight) {
        currentHeight = height
        let newHeight = UIScreen.main.bounds.height * height.heightPercentage
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.heightConstraint?.constant = newHeight
            self.view.layoutIfNeeded()
        }
    }
    
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view).y
        let velocity = gesture.velocity(in: view).y
        
        switch gesture.state {
        case .began:
            panStartLocation = heightConstraint?.constant ?? 0
            
        case .changed:
            let newHeight = panStartLocation - translation
            let maxHeight = UIScreen.main.bounds.height * SheetHeight.max.heightPercentage
            let minHeight = UIScreen.main.bounds.height * SheetHeight.min.heightPercentage
            
            heightConstraint?.constant = min(max(newHeight, minHeight), maxHeight)
            
        case .ended:
            let currentHeightPercentage = (heightConstraint?.constant ?? 0) / UIScreen.main.bounds.height
            
            if abs(velocity) > 1500 {
                bottomSheetHeight.accept(velocity > 0 ? .min : .max)
                return
            }
            
            if currentHeightPercentage < 0.3 {
                bottomSheetHeight.accept(.min)
            } else if currentHeightPercentage < 0.75 {
                bottomSheetHeight.accept(.mid)
            } else {
                bottomSheetHeight.accept(.max)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    
    func moveSheet(to height: SheetHeight) {
        bottomSheetHeight.accept(height)
    }
}

// MARK: - ScrollView Integration

extension BottomSheetViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentHeight != .max {
            scrollView.contentOffset.y = 0
        }
    }
}

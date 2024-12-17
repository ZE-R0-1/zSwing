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
            case .min: return 0.2
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
        view.backgroundColor = .clear
        setupUI()
        setupConstraints()
        setupGestures()
        bindHeight()
    }
    
    override func loadView() {
        view = BottomSheetView()
        view.backgroundColor = .clear
    }

    // MARK: - Setup
    private func setupUI() {
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
        panGesture.delegate = self
        contentView.addGestureRecognizer(panGesture)
        
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
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                self.heightConstraint?.constant = newHeight
                self.view.layoutIfNeeded()
            }
        ) { _ in
            // 애니메이션이 완료된 후 콜백
            if height == .max {
                // 최대 높이일 때 스크롤 바운스 활성화
                if let scrollView = self.contentView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                    scrollView.bounces = true
                }
            }
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
            let velocity = gesture.velocity(in: view).y
            
            // 속도 기준을 낮추고, mid 상태를 고려하도록 수정
            if abs(velocity) > 1000 {
                if velocity > 0 { // 아래로 스와이프
                    if currentHeight == .max {
                        bottomSheetHeight.accept(.mid)
                    } else {
                        bottomSheetHeight.accept(.min)
                    }
                } else { // 위로 스와이프
                    if currentHeight == .min {
                        bottomSheetHeight.accept(.mid)
                    } else {
                        bottomSheetHeight.accept(.max)
                    }
                }
                return
            }
            
            // 위치 기반 판단 기준도 수정
            if currentHeightPercentage < 0.25 {
                bottomSheetHeight.accept(.min)
            } else if currentHeightPercentage < 0.6 {
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

extension BottomSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let isScrollView = otherGestureRecognizer.view is UIScrollView
        if isScrollView {
            let scrollView = otherGestureRecognizer.view as! UIScrollView
            // 스크롤뷰가 맨 위에 있고 아래로 드래그하는 경우에만 시트 제스처 허용
            if scrollView.contentOffset.y <= 0 {
                scrollView.bounces = false
                return true
            }
            scrollView.bounces = true
            return false
        }
        return false
    }
}


class BottomSheetView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let containerView = subviews.first(where: { $0.layer.cornerRadius == 20 }) {
            let containerPoint = convert(point, to: containerView)
            return containerView.bounds.contains(containerPoint)
        }
        return super.point(inside: point, with: event)
    }
}

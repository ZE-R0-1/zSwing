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
    // MARK: - Sheet Height States
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
    private let disposeBag = DisposeBag()
    private var viewModel: MapViewModel?
    private var bottomConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var currentHeight: SheetHeight = .mid
    private var previousPanPoint: CGFloat = 0
    private var contentScrollView: UIScrollView?
    private var currentContent: BottomSheetContent?
    private var panStartLocation: CGFloat = 0
    private var isDraggingFromNonScrollView: Bool = false
    
    weak var delegate: BottomSheetDelegate?
    
    // MARK: - Outputs
    let heightPercentage = BehaviorRelay<CGFloat>(value: 0.6)
    
    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        
        addSubview(headerView)
        headerView.addSubview(dragIndicatorView)
        addSubview(contentView)
        
        bottomConstraint = bottomAnchor.constraint(equalTo: superview?.bottomAnchor ?? bottomAnchor)
        heightConstraint = heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * currentHeight.heightPercentage)
        
        guard let bottomConstraint = bottomConstraint,
              let heightConstraint = heightConstraint else { return }
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview?.leadingAnchor ?? leadingAnchor),
            trailingAnchor.constraint(equalTo: superview?.trailingAnchor ?? trailingAnchor),
            bottomConstraint,
            heightConstraint,
            
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            dragIndicatorView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            dragIndicatorView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            dragIndicatorView.widthAnchor.constraint(equalToConstant: 40),
            dragIndicatorView.heightAnchor.constraint(equalToConstant: 4),
            
            contentView.topAnchor.constraint(equalTo: dragIndicatorView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Gesture Setup
    private func setupGestures() {
        let headerPanGesture = UIPanGestureRecognizer()
        headerView.addGestureRecognizer(headerPanGesture)
        
        headerPanGesture.rx.event
            .subscribe(onNext: { [weak self] gesture in
                self?.isDraggingFromNonScrollView = true
                self?.handlePanGesture(gesture)
            })
            .disposed(by: disposeBag)
        
        let contentPanGesture = rx.panGesture()
        
        contentPanGesture
            .when(.began, .changed, .ended)
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                
                // Check if the gesture started in a non-scrollview area
                if gesture.state == .began {
                    let location = gesture.location(in: self)
                    if let scrollView = self.contentScrollView,
                       let scrollViewFrame = scrollView.superview?.convert(scrollView.frame, to: self) {
                        self.isDraggingFromNonScrollView = !scrollViewFrame.contains(location)
                    }
                }
                
                self.handlePanGesture(gesture)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Content Management
    func transition(to contentType: BottomSheetContentType, animated: Bool = true) {
        currentContent?.prepareForReuse()
        currentContent?.removeFromSuperview()
        
        let newContent: BottomSheetContent
        switch contentType {
        case .playgroundList:
            let listContent = PlaygroundListContent()
            if let viewModel = self.viewModel {
                listContent.bind(to: viewModel)
            }
            newContent = listContent
        case .playgroundDetail(let playground):
            newContent = PlaygroundDetailContent(playground: playground)
        }
        
        addContent(newContent, animated: animated)
    }
    
    func bind(to viewModel: MapViewModel) {
        self.viewModel = viewModel
        if let listContent = currentContent as? PlaygroundListContent {
            listContent.bind(to: viewModel)
        }
    }
    
    func addContent(_ content: BottomSheetContent, animated: Bool) {
        currentContent = content
        
        if let detailContent = content as? PlaygroundDetailContent {
            detailContent.closeButtonTapped
                .subscribe(onNext: { [weak self] _ in
                    self?.transition(to: .playgroundList, animated: true)
                })
                .disposed(by: disposeBag)
        }
        
        if animated {
            UIView.transition(
                with: contentView,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    self.contentView.subviews.forEach { $0.removeFromSuperview() }
                    self.addContentView(content)
                }
            )
        } else {
            contentView.subviews.forEach { $0.removeFromSuperview() }
            addContentView(content)
        }
        
        contentScrollView = content.contentScrollView
        updateScrollEnabled()
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
        
        if let scrollView = view as? UIScrollView {
            contentScrollView = scrollView
            scrollView.delegate = self
            updateScrollEnabled()
        }
    }
    
    func showSheet() {
        updateHeight(.mid)
    }
    
    // MARK: - Private Helper Methods
    private func updateScrollEnabled() {
        if let scrollView = contentScrollView {
            scrollView.isScrollEnabled = currentHeight == .max
            
            if currentHeight != .max {
                scrollView.setContentOffset(.zero, animated: true)
            }
        }
    }
    
    private func updateHeight(_ height: SheetHeight, animated: Bool = true) {
        currentHeight = height
        let newHeight = UIScreen.main.bounds.height * height.heightPercentage
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.heightConstraint?.constant = newHeight
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.updateScrollEnabled()
            }
        } else {
            heightConstraint?.constant = newHeight
            updateScrollEnabled()
        }
        
        heightPercentage.accept(height.heightPercentage)
        delegate?.bottomSheet(self, heightDidChange: height.heightPercentage)
    }
    
    private func updateHeight(_ height: CGFloat, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.heightConstraint?.constant = height
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.updateScrollEnabled()
            }
        } else {
            heightConstraint?.constant = height
            updateScrollEnabled()
        }
        
        let percentage = height / UIScreen.main.bounds.height
        heightPercentage.accept(percentage)
        delegate?.bottomSheet(self, heightDidChange: percentage)
    }
    
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let scrollView = contentScrollView else { return }
        let translation = gesture.translation(in: self).y
        let velocity = gesture.velocity(in: self).y
        let screenHeight = UIScreen.main.bounds.height
        
        switch gesture.state {
        case .began:
            panStartLocation = scrollView.contentOffset.y
            previousPanPoint = heightConstraint?.constant ?? 0
            
        case .changed:
            if currentHeight == .max {
                // 테이블뷰가 맨 위에 있거나 non-scrollView 영역을 드래그하는 경우 시트 이동
                if (scrollView.contentOffset.y <= 0 && translation > 0) || isDraggingFromNonScrollView {
                    scrollView.contentOffset.y = 0
                    let newHeight = previousPanPoint - translation
                    let heightPercentage = newHeight / screenHeight
                    updateHeight(newHeight, animated: false)
                    self.heightPercentage.accept(heightPercentage)
                }
                // 그 외의 경우는 테이블뷰 스크롤 허용
                else if !isDraggingFromNonScrollView {
                    return
                }
            }
            
            // 그 외 상태에서는 일반적인 바텀시트 동작
            let newHeight = previousPanPoint - translation
            let maxHeight = screenHeight * SheetHeight.max.heightPercentage
            let limitedHeight = min(max(newHeight, screenHeight * SheetHeight.min.heightPercentage), maxHeight)
            let heightPercentage = limitedHeight / screenHeight
            updateHeight(limitedHeight, animated: false)
            self.heightPercentage.accept(heightPercentage)
            
        case .ended, .cancelled:
            isDraggingFromNonScrollView = false
            let currentHeightPercentage = (heightConstraint?.constant ?? 0) / screenHeight
            
            if abs(velocity) > 1500 {
                if velocity > 0 {
                    if currentHeight == .max && (scrollView.contentOffset.y <= 0 || isDraggingFromNonScrollView) {
                        updateHeight(.mid)
                    } else if currentHeight != .max {
                        updateHeight(.min)
                    }
                } else {
                    if currentHeight == .min {
                        updateHeight(.mid)
                    } else {
                        updateHeight(.max)
                    }
                }
                return
            }
            
            let targetHeight: SheetHeight
            if currentHeightPercentage < 0.3 {
                targetHeight = .min
            } else if currentHeightPercentage < 0.75 {
                targetHeight = .mid
            } else {
                targetHeight = .max
            }
            
            updateHeight(targetHeight)
            
        default:
            break
        }
    }
    
    // MARK: - Layout Updates
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = superview {
            bottomConstraint?.isActive = false
            bottomConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            bottomConstraint?.isActive = true
        }
    }
}

// MARK: - UIScrollViewDelegate
extension CustomBottomSheetView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentHeight == .max && scrollView.contentOffset.y <= 0 {
            scrollView.contentOffset.y = 0
        }
    }
}

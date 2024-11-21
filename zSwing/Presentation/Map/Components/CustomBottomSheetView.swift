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
            case .min: return 0.15
            case .mid: return 0.4
            case .max: return 0.9
            }
        }
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var bottomConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var currentHeight: SheetHeight = .mid
    private var previousPanPoint: CGFloat = 0
    private var selectedCategories = BehaviorRelay<Set<String>>(value: ["전체"])
    private var contentScrollView: UIScrollView?
    
    private let visibleCategoriesCount = 3  // 초기에 보여줄 카테고리 수
    private let expandStep = 2  // 한 번에 추가로 보여줄 카테고리 수
    private var currentlyVisibleCount = 2  // 현재 보이는 카테고리 수
    private var allCategories: [CategoryInfo] = []  // 모든 카테고리 저장
    
    private var isTableViewScrolled = false
    private var panStartLocation: CGFloat = 0
    
    // MARK: - Outputs
    let heightPercentage = BehaviorRelay<CGFloat>(value: 0.6)
    let isDismissed = PublishRelay<Bool>()
    let categoriesSelected = PublishRelay<Set<String>>()
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let categoryScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let categoryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
        setupExpandButton()
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
        headerView.addSubview(titleLabel)
        headerView.addSubview(loadingIndicator)
        addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStackView)
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
            
            titleLabel.topAnchor.constraint(equalTo: dragIndicatorView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: loadingIndicator.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            categoryScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            categoryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 50),
            
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.topAnchor, constant: 8),
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 20),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -20),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: -8),
            categoryStackView.heightAnchor.constraint(equalToConstant: 34),
            
            contentView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupExpandButton() {
        expandButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.expandCategories()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Gesture Setup
    private func setupGestures() {
        let panGesture = rx.panGesture()
        
        panGesture
            .when(.began, .changed, .ended)
            .subscribe(onNext: { [weak self] gesture in
                self?.handlePanGesture(gesture)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Category Management
    private func addCategoryButton(for categoryInfo: CategoryInfo) {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        let attributedTitle = NSMutableAttributedString(
            string: categoryInfo.name,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]
        )
        attributedTitle.append(NSAttributedString(
            string: " \(categoryInfo.count)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.systemGray
            ]
        ))
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        selectedCategories
            .map { $0.contains(categoryInfo.name) }
            .bind { [weak button] isSelected in
                button?.backgroundColor = isSelected ? .systemBlue : .systemGray6
                
                let attributedTitle = NSMutableAttributedString(
                    string: categoryInfo.name,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                        .foregroundColor: isSelected ? UIColor.white : UIColor.black
                    ]
                )
                attributedTitle.append(NSAttributedString(
                    string: " \(categoryInfo.count)",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                        .foregroundColor: isSelected ? UIColor.white.withAlphaComponent(0.8) : UIColor.systemGray
                    ]
                ))
                button?.setAttributedTitle(attributedTitle, for: .normal)
            }
            .disposed(by: disposeBag)
        
        button.rx.tap
            .withLatestFrom(selectedCategories) { _, categories -> Set<String> in
                var updatedCategories = categories
                if categoryInfo.name == "전체" {
                    return ["전체"]
                } else {
                    updatedCategories.remove("전체")
                    if updatedCategories.contains(categoryInfo.name) {
                        updatedCategories.remove(categoryInfo.name)
                    } else {
                        updatedCategories.insert(categoryInfo.name)
                    }
                    if updatedCategories.isEmpty {
                        updatedCategories = ["전체"]
                    }
                }
                return updatedCategories
            }
            .bind(to: selectedCategories)
            .disposed(by: disposeBag)
        
        categoryStackView.addArrangedSubview(button)
    }
    
    private func updateExpandButton(remainingCount: Int) {
        let buttonSize: CGFloat = 34
        expandButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        expandButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        expandButton.setTitle("+\(remainingCount)", for: .normal)
    }
    
    private func expandCategories() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.currentlyVisibleCount = min(
                self.currentlyVisibleCount + self.expandStep,
                self.allCategories.count
            )
            self.updateVisibleCategories()
        }
    }
    
    private func updateVisibleCategories() {
        categoryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let totalCategory = allCategories.first(where: { $0.name == "전체" }) {
            addCategoryButton(for: totalCategory)
        }
        
        let remainingCategories = allCategories.filter { $0.name != "전체" }
        let visibleCategories = remainingCategories.prefix(currentlyVisibleCount - 1)
        
        visibleCategories.forEach { categoryInfo in
            addCategoryButton(for: categoryInfo)
        }
        
        if currentlyVisibleCount < allCategories.count {
            let remainingCount = allCategories.count - currentlyVisibleCount
            updateExpandButton(remainingCount: remainingCount)
            categoryStackView.addArrangedSubview(expandButton)
        }
    }
    
    // MARK: - Public Methods
    func bind(to viewModel: MapViewModel) {
        viewModel.locationTitle
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.categories
            .map { $0.map { CategoryInfo(name: $0.name, count: $0.count) } }
            .subscribe(onNext: { [weak self] categories in
                self?.updateCategories(categories)
            })
            .disposed(by: disposeBag)
        
        selectedCategories
            .bind(to: viewModel.categoriesSelected)
            .disposed(by: disposeBag)
    }
    
    func updateCategories(_ categories: [CategoryInfo]) {
        allCategories = categories
        currentlyVisibleCount = visibleCategoriesCount
        updateVisibleCategories()
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
        
        // UITableView나 UIScrollView인 경우 저장하고 delegate 설정
        if let scrollView = view as? UIScrollView {
            contentScrollView = scrollView
            scrollView.delegate = self
            updateScrollEnabled()
        }
    }
    
    func showSheet() {
        updateHeight(.mid)
    }
    
    // MARK: - Private Methods
    private func updateScrollEnabled() {
        if let scrollView = contentScrollView {
            // 최대 높이일 때만 스크롤 활성화
            scrollView.isScrollEnabled = currentHeight == .max
            
            // 스크롤 위치 초기화 (선택사항)
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
            // max 상태에서의 처리
            if currentHeight == .max {
                // 테이블뷰가 맨 위에 있고 아래로 드래그하는 경우
                if scrollView.contentOffset.y <= 0 && translation > 0 {
                    scrollView.contentOffset.y = 0
                    let newHeight = previousPanPoint - translation
                    let heightPercentage = newHeight / screenHeight
                    updateHeight(newHeight, animated: false)
                    self.heightPercentage.accept(heightPercentage)
                }
                // 그 외의 경우는 테이블뷰 스크롤 허용
                return
            }
            
            // 그 외 상태에서는 일반적인 바텀시트 동작
            let newHeight = previousPanPoint - translation
            let maxHeight = screenHeight * SheetHeight.max.heightPercentage
            let limitedHeight = min(max(newHeight, screenHeight * SheetHeight.min.heightPercentage), maxHeight)
            let heightPercentage = limitedHeight / screenHeight
            updateHeight(limitedHeight, animated: false)
            self.heightPercentage.accept(heightPercentage)
            
        case .ended, .cancelled:
            let currentHeightPercentage = (heightConstraint?.constant ?? 0) / screenHeight
            
            // 속도가 빠른 경우 스와이프 방향으로 이동
            if abs(velocity) > 1500 {
                if velocity > 0 {  // 아래로 스와이프
                    if currentHeight == .max && scrollView.contentOffset.y <= 0 {
                        updateHeight(.mid)
                    } else if currentHeight != .max {
                        updateHeight(.min)
                    }
                } else {  // 위로 스와이프
                    if currentHeight == .min {
                        updateHeight(.mid)
                    } else {
                        updateHeight(.max)
                    }
                }
                return
            }
            
            // 속도가 느린 경우 가장 가까운 높이로 이동
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        categoryScrollView.layoutIfNeeded()
        
        if let lastButton = categoryStackView.arrangedSubviews.last {
            let targetRect = lastButton.convert(lastButton.bounds, to: categoryScrollView)
            categoryScrollView.scrollRectToVisible(targetRect, animated: true)
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isTableViewScrolled = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isTableViewScrolled = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isTableViewScrolled = false
    }
}

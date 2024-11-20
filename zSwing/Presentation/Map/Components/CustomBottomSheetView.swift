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
    
    private let visibleCategoriesCount = 3  // 초기에 보여줄 카테고리 수
    private let expandStep = 2  // 한 번에 추가로 보여줄 카테고리 수
    private var currentlyVisibleCount = 2  // 현재 보이는 카테고리 수
    private var allCategories: [CategoryInfo] = []  // 모든 카테고리 저장
    
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
        
        // 카테고리 이름과 수량을 함께 표시
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
        
        // 선택 상태에 따른 스타일링
        selectedCategories
            .map { $0.contains(categoryInfo.name) }
            .bind { [weak button] isSelected in
                button?.backgroundColor = isSelected ? .systemBlue : .systemGray6
                
                // 선택 상태에 따른 텍스트 색상 변경
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
        
        // 탭 이벤트 처리
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
        
        // "전체" 카테고리는 항상 표시
        if let totalCategory = allCategories.first(where: { $0.name == "전체" }) {
            addCategoryButton(for: totalCategory)
        }
        
        // 나머지 카테고리들 중 현재 보여져야 할 만큼만 표시
        let remainingCategories = allCategories.filter { $0.name != "전체" }
        let visibleCategories = remainingCategories.prefix(currentlyVisibleCount - 1)
        
        visibleCategories.forEach { categoryInfo in
            addCategoryButton(for: categoryInfo)
        }
        
        // 더 보여줄 카테고리가 있는 경우에만 확장 버튼 표시
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
    }
    
    func showSheet() {
        updateHeight(.mid)
    }
    
    // MARK: - Gesture Handling
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self).y
        let velocity = gesture.velocity(in: self).y
        let screenHeight = UIScreen.main.bounds.height
        
        switch gesture.state {
        case .began:
            previousPanPoint = heightConstraint?.constant ?? 0
            
        case .changed:
            let newHeight = previousPanPoint - translation
            let heightPercentage = newHeight / screenHeight
            updateHeight(newHeight, animated: false)
            self.heightPercentage.accept(heightPercentage)
            
        case .ended, .cancelled:
            let currentHeightPercentage = (heightConstraint?.constant ?? 0) / screenHeight
            
            // 속도가 빠른 경우 스와이프 방향으로 이동
            if abs(velocity) > 1500 {
                if velocity > 0 {  // 아래로 스와이프
                    if currentHeight == .max {
                        updateHeight(.mid)
                    } else {
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
    
    // MARK: - Private Methods
    private func updateHeight(_ height: SheetHeight, animated: Bool = true) {
        currentHeight = height
        let newHeight = UIScreen.main.bounds.height * height.heightPercentage
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.heightConstraint?.constant = newHeight
                self.superview?.layoutIfNeeded()
            }
        } else {
            heightConstraint?.constant = newHeight
        }
        
        heightPercentage.accept(height.heightPercentage)
    }
    
    private func updateHeight(_ height: CGFloat, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.heightConstraint?.constant = height
                self.superview?.layoutIfNeeded()
            }
        } else {
            heightConstraint?.constant = height
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
        
        // 스크롤뷰가 새로운 컨텐츠 크기에 맞게 조정되도록
        categoryScrollView.layoutIfNeeded()
        
        // 필요한 경우 스크롤 위치 조정
        if let lastButton = categoryStackView.arrangedSubviews.last {
            let targetRect = lastButton.convert(lastButton.bounds, to: categoryScrollView)
            categoryScrollView.scrollRectToVisible(targetRect, animated: true)
        }
    }
}

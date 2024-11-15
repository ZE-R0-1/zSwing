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
            case .mid: return 0.6
            case .max: return 0.9
            }
        }
    }
    
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
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var bottomConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var currentHeight: SheetHeight = .mid
    private var previousPanPoint: CGFloat = 0
    private var selectedCategory = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Outputs
    let heightPercentage = BehaviorRelay<CGFloat>(value: 0.6)
    let isDismissed = PublishRelay<Bool>()
    let categorySelected = PublishRelay<String>()
    
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
    
    // MARK: - Public Methods    
    func bind(to viewModel: MapViewModel) {
        // 제목 바인딩
        viewModel.locationTitle
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 로딩 상태 바인딩
        viewModel.isLoading
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        // 카테고리 바인딩
        viewModel.categories
            .subscribe(onNext: { [weak self] categories in
                self?.updateCategories(categories)
            })
            .disposed(by: disposeBag)
        
        // 선택된 카테고리 바인딩
        selectedCategory
            .compactMap { $0 }
            .bind(to: viewModel.categorySelected)
            .disposed(by: disposeBag)
    }
    
    func updateCategories(_ categories: [String]) {
        categoryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // "전체" 카테고리 추가
        addCategoryButton(title: "전체")
        
        // 나머지 카테고리 추가
        categories.forEach { category in
            addCategoryButton(title: category)
        }
    }
    
    private func addCategoryButton(title: String) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // 선택 상태 스타일링
        selectedCategory
            .map { $0 == title }
            .bind { [weak button] isSelected in
                button?.backgroundColor = isSelected ? .systemBlue : .systemGray6
                button?.setTitleColor(isSelected ? .white : .black, for: .normal)
            }
            .disposed(by: disposeBag)
        
        // 탭 이벤트 처리
        button.rx.tap
            .map { title }
            .bind(to: selectedCategory)
            .disposed(by: disposeBag)
        
        categoryStackView.addArrangedSubview(button)
    }

    func updateTitle(_ title: String) {
        titleLabel.text = title
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
    
    // MARK: - Private Methods
    private func createCategoryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // 선택된 카테고리 스타일 변경
        selectedCategory
            .map { $0 == title }
            .subscribe(onNext: { [weak button] isSelected in
                button?.backgroundColor = isSelected ? .systemBlue : .systemGray6
                button?.setTitleColor(isSelected ? .white : .black, for: .normal)
            })
            .disposed(by: disposeBag)
        
        return button
    }
    
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
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = superview {
            bottomConstraint?.isActive = false
            bottomConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            bottomConstraint?.isActive = true
        }
    }
}

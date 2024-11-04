//
//  RideDetailBottomSheetView.swift
//  zSwing
//
//  Created by USER on 10/29/24.
//

import UIKit

/// 놀이기구 상세 정보를 보여주는 바텀 시트 뷰
/// 드래그로 높이를 조절할 수 있으며, 카테고리 선택과 상세 정보 표시 기능을 제공합니다.
class RideDetailBottomSheetView: UIView {
    // MARK: - Properties
    
    /// 바텀 시트 상단의 드래그 표시 뷰
    private let dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 놀이기구 정보를 표시하는 수직 스택 뷰
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    /// 놀이기구 카테고리 선택을 위한 수평 스크롤 컬렉션 뷰
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    /// 드래그 제스처 관련 속성들
    private var initialTouchPoint: CGPoint = .zero
    private var currentHeight: CGFloat = 0
    private var selectedCategory: RideCategory? = .swing  // 기본값으로 그네 선택
    private var onCategorySelected: ((RideCategory?) -> Void)?
    
    // 바텀 시트의 높이 상태값들
    let defaultHeight: CGFloat = UIScreen.main.bounds.height * 0.4  // 기본 높이 (화면의 40%)
    let maximumHeight: CGFloat = UIScreen.main.bounds.height * 0.9  // 최대 높이 (화면의 90%)
    let minimumHeight: CGFloat = UIScreen.main.bounds.height * 0.2  // 최소 높이 (화면의 20%)
    
    /// 바텀 시트의 높이를 조절하는 제약 조건
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
    
    // MARK: - Setup Methods
    
    /// UI 기본 설정을 수행하는 메서드
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]  // 상단 모서리만 라운드 처리
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        translatesAutoresizingMaskIntoConstraints = false
        
        setupDragIndicator()
        setupInfoStackView()
        setupCategoryCollectionView()
    }
    
    /// 드래그 표시 뷰 설정
    private func setupDragIndicator() {
        addSubview(dragIndicator)
        NSLayoutConstraint.activate([
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 5),
            dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        ])
    }
    
    /// 정보 스택 뷰 설정
    private func setupInfoStackView() {
        addSubview(infoStackView)
        NSLayoutConstraint.activate([
            infoStackView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    /// 카테고리 컬렉션 뷰 설정
    private func setupCategoryCollectionView() {
        addSubview(categoryCollectionView)
        
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        
        categoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    /// 제스처 인식기 설정
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - Gesture Handling
    
    /// 드래그 제스처 처리
    /// - Parameter gesture: 감지된 팬 제스처
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
            
            if velocity.y > 1000 {
                // 빠른 아래 방향 스와이프: 최소 높이로
                animateHeight(to: minimumHeight)
            } else if velocity.y < -1000 {
                // 빠른 위 방향 스와이프: 최대 높이로
                animateHeight(to: maximumHeight)
            } else if projectedHeight < (defaultHeight + minimumHeight) / 2 {
                // 최소~기본 높이의 중간 지점보다 아래면 최소 높이로
                animateHeight(to: minimumHeight)
            } else if projectedHeight > (defaultHeight + maximumHeight) / 2 {
                // 기본~최대 높이의 중간 지점보다 위면 최대 높이로
                animateHeight(to: maximumHeight)
            } else {
                // 그 외의 경우 기본 높이로
                animateHeight(to: defaultHeight)
            }
            
        default:
            break
        }
    }
    
    /// 바텀 시트의 높이를 업데이트하고 지도 뷰의 레이아웃을 조정
    /// - Parameter height: 설정할 높이 값
    func updateHeight(_ height: CGFloat) {
        let newHeight = min(max(height, minimumHeight), maximumHeight)
        heightConstraint?.constant = newHeight
        
        if let mapVC = superview?.next as? MapViewController {
            mapVC.updateMapLayoutMargins(bottomInset: newHeight)
        }
        
        superview?.layoutIfNeeded()
    }
    
    /// 바텀 시트의 높이를 애니메이션과 함께 변경
    /// - Parameter height: 목표 높이 값
    private func animateHeight(to height: CGFloat) {
        UIView.animate(withDuration: 0.3,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 0.5,
                      options: .curveEaseOut,
                      animations: { [weak self] in
            self?.heightConstraint?.constant = height
            if let mapVC = self?.superview?.next as? MapViewController {
                mapVC.updateMapLayoutMargins(bottomInset: height)
            }
            self?.superview?.layoutIfNeeded()
        })
    }
    
    // MARK: - Public Methods
    
    /// 기본 상태로 바텀 시트를 표시
    /// - Parameter onCategorySelected: 카테고리 선택 시 호출될 콜백
    func showDefaultState(onCategorySelected: @escaping (RideCategory?) -> Void) {
        self.onCategorySelected = onCategorySelected
        isHidden = false
        heightConstraint?.constant = minimumHeight
        
        infoStackView.isHidden = true
        categoryCollectionView.isHidden = false
        
        // 초기 선택된 카테고리(그네) 콜백 호출
        onCategorySelected(selectedCategory)
        
        if let mapVC = superview?.next as? MapViewController {
            mapVC.updateMapLayoutMargins(bottomInset: minimumHeight)
        }
    }
    
    /// 특정 놀이기구의 상세 정보를 표시
    /// - Parameter rideInfo: 표시할 놀이기구 정보
    func showRideDetail(for rideInfo: RideInfo) {
        // 기존 정보 제거
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 새로운 정보 추가
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
        
        categoryCollectionView.isHidden = true
        infoStackView.isHidden = false
        
        // 상세 정보 표시를 위해 높이 조정
        animateHeight(to: defaultHeight)
    }
    
    // MARK: - Private Helper Methods
    
    /// 레이블 생성 헬퍼 메서드
    private func createLabel(text: String, font: UIFont, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
    
    /// 구분선 생성 헬퍼 메서드
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension RideDetailBottomSheetView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    /// 컬렉션 뷰의 아이템 개수 반환
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return RideCategory.allCases.count
    }
    
    /// 각 아이템의 셀 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let category = RideCategory.allCases[indexPath.item]
        cell.configure(with: category.displayName, isSelected: category == selectedCategory)
        return cell
    }
    
    /// 각 아이템의 크기 계산
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let category = RideCategory.allCases[indexPath.item]
        let width = category.displayName.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)]).width + 40
        return CGSize(width: width, height: 36)
    }
    
    /// 카테고리 선택 처리
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = RideCategory.allCases[indexPath.item]
        // 이미 선택된 카테고리를 다시 선택하면 선택 해제
        if category == selectedCategory {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        collectionView.reloadData()
        onCategorySelected?(selectedCategory)
    }
}

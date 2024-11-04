//
//  RideDetailBottomSheetView.swift
//  zSwing
//
//  Created by USER on 10/29/24.
//

import UIKit

class RideDetailBottomSheetView: UIView {
    // MARK: - Properties
    private let dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
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
    
    private var initialTouchPoint: CGPoint = .zero
    private var currentHeight: CGFloat = 0
    private var selectedCategory: RideCategory?
    private var onCategorySelected: ((RideCategory?) -> Void)?
    
    // Height states
    let defaultHeight: CGFloat = UIScreen.main.bounds.height * 0.4  // 40%
    let maximumHeight: CGFloat = UIScreen.main.bounds.height * 0.9  // 90%
    let minimumHeight: CGFloat = UIScreen.main.bounds.height * 0.2  // 20%
    
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
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        translatesAutoresizingMaskIntoConstraints = false
        
        setupDragIndicator()
        setupInfoStackView()
        setupCategoryCollectionView()
    }
    
    private func setupDragIndicator() {
        addSubview(dragIndicator)
        NSLayoutConstraint.activate([
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 5),
            dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        ])
    }
    
    private func setupInfoStackView() {
        addSubview(infoStackView)
        NSLayoutConstraint.activate([
            infoStackView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
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
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - Gesture Handling
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
                // Fast downward swipe
                animateHeight(to: minimumHeight)
            } else if velocity.y < -1000 {
                // Fast upward swipe
                animateHeight(to: maximumHeight)
            } else if projectedHeight < (defaultHeight + minimumHeight) / 2 {
                // Below middle of minimum and default
                animateHeight(to: minimumHeight)
            } else if projectedHeight > (defaultHeight + maximumHeight) / 2 {
                // Above middle of default and maximum
                animateHeight(to: maximumHeight)
            } else {
                // Return to default height
                animateHeight(to: defaultHeight)
            }
            
        default:
            break
        }
    }
    
    private func updateHeight(_ height: CGFloat) {
        let newHeight = min(max(height, minimumHeight), maximumHeight)
        heightConstraint?.constant = newHeight
        
        if let mapVC = superview?.next as? MapViewController {
            mapVC.updateMapLayoutMargins(bottomInset: newHeight)
        }
        
        superview?.layoutIfNeeded()
    }
    
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
    func showDefaultState(onCategorySelected: @escaping (RideCategory?) -> Void) {
        self.onCategorySelected = onCategorySelected
        isHidden = false
        heightConstraint?.constant = minimumHeight
        
        infoStackView.isHidden = true
        categoryCollectionView.isHidden = false
        
        if let mapVC = superview?.next as? MapViewController {
            mapVC.updateMapLayoutMargins(bottomInset: minimumHeight)
        }
    }
    
    func showRideDetail(for rideInfo: RideInfo) {
        // Clear previous info
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new info
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
        
        // Animate to detail view
        animateHeight(to: defaultHeight)
    }
    
    // MARK: - Private Methods
    private func createLabel(text: String, font: UIFont, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
}

// MARK: - UICollectionView
extension RideDetailBottomSheetView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return RideCategory.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let category = RideCategory.allCases[indexPath.item]
        cell.configure(with: category.displayName, isSelected: category == selectedCategory)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let category = RideCategory.allCases[indexPath.item]
        let width = category.displayName.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)]).width + 40
        return CGSize(width: width, height: 36)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = RideCategory.allCases[indexPath.item]
        if category == selectedCategory {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        collectionView.reloadData()
        onCategorySelected?(selectedCategory)
    }
}

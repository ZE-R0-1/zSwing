//
//  RideDetailView.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit
import CoreLocation

class RideDetailView: UIView {
    // MARK: - Properties
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
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private var playgrounds: [PlaygroundItem] = []
    private var selectedCategory: RideCategory? = .swing
    private var onCategorySelected: ((RideCategory?) -> Void)?
    private var userLocation: CLLocation?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .clear
        setupInfoStackView()
        setupCategoryCollectionView()
        setupTableView()
    }
    
    private func setupInfoStackView() {
        addSubview(infoStackView)
        NSLayoutConstraint.activate([
            infoStackView.topAnchor.constraint(equalTo: topAnchor),
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
            categoryCollectionView.topAnchor.constraint(equalTo: topAnchor),
            categoryCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTableView() {
        addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlaygroundCell.self, forCellReuseIdentifier: "PlaygroundCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func showDefaultState(with annotations: [RideAnnotation], userLocation: CLLocation?, onCategorySelected: @escaping (RideCategory?) -> Void) {
        self.onCategorySelected = onCategorySelected
        self.userLocation = userLocation
        
        updatePlaygrounds(with: annotations)
        
        infoStackView.isHidden = true
        categoryCollectionView.isHidden = false
        tableView.isHidden = false
        
        onCategorySelected(selectedCategory)
    }
    
    func showRideDetail(for rideInfo: RideInfo) {
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
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
        tableView.isHidden = true
        infoStackView.isHidden = false
    }
    
    // MARK: - Private Helper Methods
    private func updatePlaygrounds(with annotations: [RideAnnotation]) {
        playgrounds = annotations.map { annotation in
            PlaygroundItem(
                rideInfo: annotation.rideInfo,
                coordinate: annotation.coordinate,
                userLocation: userLocation
            )
        }.sorted { $0.distance < $1.distance }
        
        tableView.reloadData()
    }
    
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

// MARK: - UITableViewDelegate & DataSource
extension RideDetailView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playgrounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaygroundCell", for: indexPath) as! PlaygroundCell
        cell.configure(with: playgrounds[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showRideDetail(for: playgrounds[indexPath.row].rideInfo)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension RideDetailView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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

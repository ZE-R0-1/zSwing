//
//  HomeViewController.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit

class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    
    // MARK: - UI Components
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let findPlaygroundLabel: UILabel = {
        let label = UILabel()
        label.text = "놀이기구 찾아보기"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var facilityCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.register(FacilityCell.self, forCellWithReuseIdentifier: "FacilityCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Properties
    private let facilities = [
        PlaygroundFacility(name: "그네", imageName: "arrow.up.and.down"), // 그네의 움직임을 표현
        PlaygroundFacility(name: "미끄럼틀", imageName: "arrow.down.forward.circle.fill"),
        PlaygroundFacility(name: "정글짐", imageName: "cube.transparent"),
        PlaygroundFacility(name: "공중기구", imageName: "airplane"),
        PlaygroundFacility(name: "회전기구", imageName: "rotate.3d"),
        PlaygroundFacility(name: "흔들기구", imageName: "wave.3.right"),
        PlaygroundFacility(name: "오르는기구", imageName: "arrow.up.circle"),
        PlaygroundFacility(name: "건너는기구", imageName: "arrow.left.and.right"),
        PlaygroundFacility(name: "조합놀이대", imageName: "square.stack.3d.up"),
        PlaygroundFacility(name: "철봉", imageName: "figure.gymnastics"),
        PlaygroundFacility(name: "늑목", imageName: "arrow.up.and.down.square"), // 늑목의 형태를 표현
        PlaygroundFacility(name: "평균대", imageName: "minus")
    ]
    
    // MARK: - Initialization
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(welcomeLabel)
        view.addSubview(findPlaygroundLabel)
        view.addSubview(facilityCollectionView)
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            findPlaygroundLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 32),
            findPlaygroundLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            facilityCollectionView.topAnchor.constraint(equalTo: findPlaygroundLabel.bottomAnchor, constant: 16),
            facilityCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            facilityCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            facilityCollectionView.heightAnchor.constraint(equalToConstant: 400) // 필요에 따라 조정
        ])
    }
    
    private func configureUI() {
        welcomeLabel.attributedText = viewModel.welcomeMessage
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return facilities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FacilityCell", for: indexPath) as! FacilityCell
        let facility = facilities[indexPath.item]
        cell.configure(with: facility)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow: CGFloat = 6
        let availableWidth = collectionView.bounds.width
        let width = availableWidth / numberOfItemsPerRow
        
        return CGSize(width: width, height: width + 24)
    }
}

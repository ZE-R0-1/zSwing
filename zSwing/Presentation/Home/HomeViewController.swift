//
//  HomeViewController.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit
import RxSwift

class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    
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
        collectionView.isScrollEnabled = false
        collectionView.register(FacilityCell.self, forCellWithReuseIdentifier: "FacilityCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
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
        bindViewModel()
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
    
    private func bindViewModel() {
        // welcomeMessage 바인딩
        viewModel.welcomeMessage
            .bind(to: welcomeLabel.rx.attributedText)
            .disposed(by: disposeBag)
        
        // CollectionView 데이터 바인딩
        viewModel.facilities
            .bind(to: facilityCollectionView.rx.items(cellIdentifier: "FacilityCell",
                  cellType: FacilityCell.self)) { _, facility, cell in
                cell.configure(with: facility)
            }
            .disposed(by: disposeBag)
        
        // Cell 선택 처리
        facilityCollectionView.rx.itemSelected
            .withLatestFrom(viewModel.facilities) { indexPath, facilities in
                return facilities[indexPath.item]
            }
            .subscribe(onNext: { [weak self] facility in
                self?.viewModel.didSelectFacility(facility)
            })
            .disposed(by: disposeBag)
            
        // Cell 크기 설정
        facilityCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)

    }
}

// MARK: - UICollectionView DataSource & Delegate
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow: CGFloat = 6
        let availableWidth = collectionView.bounds.width
        let width = availableWidth / numberOfItemsPerRow
        
        return CGSize(width: width, height: width + 24)
    }
}

//
//  PlaygroundClusterView.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import UIKit
import RxSwift
import RxRelay
import CoreLocation

class PlaygroundClusterView: UIView {
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ClusterItemCell.self, forCellWithReuseIdentifier: ClusterItemCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Properties
    let playgroundSelected = PublishRelay<Playground>()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with viewModel: PlaygroundClusterViewModel) {
        Observable.just(viewModel.items)
            .bind(to: collectionView.rx.items(
                cellIdentifier: ClusterItemCell.identifier,
                cellType: ClusterItemCell.self
            )) { _, item, cell in
                cell.configure(
                    name: item.playground.name,
                    distance: PlaygroundDetailViewModel.formatDistance(item.distance)
                )
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.modelSelected((Playground, CLLocationDistance).self)
            .map { $0.0 }
            .bind(to: playgroundSelected)
            .disposed(by: disposeBag)
            
        // CollectionView 레이아웃 설정
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 44)
        }
    }
}

// MARK: - ClusterItemCell
class ClusterItemCell: UICollectionViewCell {
    static let identifier = "ClusterItemCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 14
        
        // 그림자 설정
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        
        // 그림자를 위해 clipsToBounds는 false로 설정
        view.clipsToBounds = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = HomeViewModel.themeColor
        return label
    }()
    
    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
            updateSelection()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(distanceLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func configure(name: String, distance: String) {
        nameLabel.text = name
        distanceLabel.text = distance
    }
    
    private func updateSelection() {
        nameLabel.font = isSelected ? .systemFont(ofSize: 16, weight: .bold) : .systemFont(ofSize: 16)
        containerView.backgroundColor = isSelected ? .systemGray6 : .systemBackground
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if !isSelected {
            containerView.backgroundColor = .systemGray6
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if !isSelected {
            containerView.backgroundColor = .systemBackground
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if !isSelected {
            containerView.backgroundColor = .systemBackground
        }
    }
}

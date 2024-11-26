//
//  PlaygroundListContent.swift
//  zSwing
//
//  Created by USER on 11/26/24.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation

class PlaygroundListContent: UIView, BottomSheetContent {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation? {
        return locationManager.location
    }
    private var viewModel: MapViewModel?
    private var selectedCategories = BehaviorRelay<Set<String>>(value: ["전체"])
    private var allCategories: [CategoryInfo] = []
    
    var contentScrollView: UIScrollView? { tableView }
    var contentTitle: String { "놀이터 목록" }
    
    // MARK: - UI Components
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

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(PlaygroundCell.self, forCellReuseIdentifier: PlaygroundCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.delegate = nil
        table.dataSource = nil
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
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
        addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStackView)
        addSubview(tableView)
        
        NSLayoutConstraint.activate([
            categoryScrollView.topAnchor.constraint(equalTo: topAnchor),
            categoryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 50),
            
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.topAnchor, constant: 8),
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 20),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -20),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: -8),
            categoryStackView.heightAnchor.constraint(equalToConstant: 34),
            
            tableView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func addCategoryButton(for categoryInfo: CategoryInfo) {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // 카테고리 이름만 설정
        let attributedTitle = NSMutableAttributedString(
            string: categoryInfo.name,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]
        )
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        selectedCategories
            .map { $0.contains(categoryInfo.name) }
            .bind { [weak button] isSelected in
                button?.backgroundColor = isSelected ? .systemBlue : .systemGray6
                
                // 카테고리 이름만 설정
                let attributedTitle = NSMutableAttributedString(
                    string: categoryInfo.name,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                        .foregroundColor: isSelected ? UIColor.white : UIColor.black
                    ]
                )
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
    private func updateCategories(_ categories: [CategoryInfo]) {
        allCategories = categories
        categoryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // "전체" 카테고리는 항상 표시
        if let totalCategory = categories.first(where: { $0.name == "전체" }) {
            addCategoryButton(for: totalCategory)
        }
        
        // 나머지 카테고리들 모두 표시
        categories.filter { $0.name != "전체" }
            .forEach { categoryInfo in
                addCategoryButton(for: categoryInfo)
            }
    }
    
    
    func bind(to viewModel: MapViewModel) {
        self.viewModel = viewModel
        
        viewModel.categories
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] categories in
                self?.updateCategories(categories)
            })
            .disposed(by: disposeBag)
        
        selectedCategories
            .bind(to: viewModel.categoriesSelected)
            .disposed(by: disposeBag)
        
        tableView.delegate = nil
        tableView.dataSource = nil
        
        viewModel.playgrounds
            .bind(to: tableView.rx.items(
                cellIdentifier: PlaygroundCell.identifier,
                cellType: PlaygroundCell.self
            )) { [weak self] index, playground, cell in
                // currentLocation이 있으면 거리 계산
                if let currentLocation = self?.currentLocation {
                    let playgroundLocation = CLLocation(
                        latitude: playground.coordinate.latitude,
                        longitude: playground.coordinate.longitude
                    )
                    let distance = currentLocation.distance(from: playgroundLocation) / 1000.0
                    cell.configure(with: playground, distance: distance)
                } else {
                    cell.configure(with: playground, distance: nil)
                }
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let playground = self?.viewModel?.playgrounds.value[indexPath.row] else { return }
                NotificationCenter.default.post(
                    name: .playgroundSelected,
                    object: nil,
                    userInfo: ["playground": playground]
                )
            })
            .disposed(by: disposeBag)
    }
    
    func prepareForReuse() {
        viewModel = nil
    }
}

extension Notification.Name {
    static let playgroundSelected = Notification.Name("playgroundSelected")
}

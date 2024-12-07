//
//  PlaygroundListViewController.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import UIKit
import RxSwift
import RxCocoa

final class PlaygroundListViewController: BottomSheetViewController {
    // MARK: - Properties
    private let viewModel: PlaygroundListViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var locationStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private lazy var locationIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "location.fill")
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["전체", "실내", "실외"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemGray6
        control.selectedSegmentTintColor = .white
        control.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(PlaygroundCell.self, forCellReuseIdentifier: PlaygroundCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .white
        table.delegate = self
        return table
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    init(viewModel: PlaygroundListViewModel) {
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
        setupConstraints()
        bindViewModel()
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(headerView)
        headerView.addSubview(locationStackView)
        locationStackView.addArrangedSubview(locationIconImageView)
        locationStackView.addArrangedSubview(locationLabel)
        headerView.addSubview(segmentedControl)
        
        contentView.addSubview(tableView)
        tableView.addSubview(loadingIndicator)
        
        [headerView, locationStackView, locationIconImageView, locationLabel,
         segmentedControl, tableView, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            locationStackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            locationStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            locationIconImageView.widthAnchor.constraint(equalToConstant: 16),
            locationIconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            segmentedControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            segmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func bindViewModel() {
        // Location 바인딩
        viewModel.locationTitle
            .bind(to: locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 로딩 상태 바인딩
        viewModel.isLoading
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        // 테이블뷰 데이터 바인딩
        viewModel.playgrounds
            .bind(to: tableView.rx.items(
                cellIdentifier: PlaygroundCell.identifier,
                cellType: PlaygroundCell.self
            )) { _, playgroundWithDistance, cell in
                cell.configure(
                    with: playgroundWithDistance.playground,
                    distance: playgroundWithDistance.distance
                )
            }
            .disposed(by: disposeBag)
        
        // 카테고리 필터 바인딩
        segmentedControl.rx.selectedSegmentIndex
            .map { index -> Set<String> in
                switch index {
                case 0: return ["전체"]
                case 1: return ["실내"]
                case 2: return ["실외"]
                default: return ["전체"]
                }
            }
            .bind(to: viewModel.categorySelected)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func fetchPlaygrounds(for region: MapRegion) {
        viewModel.searchButtonTapped.accept(region)
    }
}

// MARK: - UITableViewDelegate
extension PlaygroundListViewController: UITableViewDelegate {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
    }
}

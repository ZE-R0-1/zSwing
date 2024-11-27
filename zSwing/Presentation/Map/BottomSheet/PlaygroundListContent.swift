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
    
    var contentScrollView: UIScrollView? { tableView }
    
    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let locationStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let locationIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "location.fill")
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let weatherLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["전체", "실내", "실외"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemGray6
        control.selectedSegmentTintColor = .white
        control.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(PlaygroundCell.self, forCellReuseIdentifier: PlaygroundCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .white
        table.delegate = nil       // 명시적으로 nil 설정
        table.dataSource = nil    // 명시적으로 nil 설정
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
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
        backgroundColor = .white
        
        // 헤더뷰 설정
        addSubview(headerView)
        
        // 위치 정보 스택뷰 설정
        headerView.addSubview(locationStackView)
        locationStackView.addArrangedSubview(locationIconImageView)
        locationStackView.addArrangedSubview(locationLabel)
        
        // 날씨 정보 레이블 설정
        headerView.addSubview(temperatureLabel)
        headerView.addSubview(weatherLabel)
        
        // 검색 버튼 설정
        headerView.addSubview(searchButton)
        
        // 세그먼트 컨트롤 설정
        headerView.addSubview(segmentedControl)
        
        // 테이블뷰 설정
        addSubview(tableView)
        
        // 로딩 인디케이터 추가
        addSubview(loadingIndicator)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            // 헤더뷰
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            // 위치 정보 스택뷰
            locationStackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            locationStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            // 위치 아이콘
            locationIconImageView.widthAnchor.constraint(equalToConstant: 16),
            locationIconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 검색 버튼
            searchButton.centerYAnchor.constraint(equalTo: locationStackView.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            searchButton.widthAnchor.constraint(equalToConstant: 24),
            searchButton.heightAnchor.constraint(equalToConstant: 24),
            
            // 날씨 정보
            temperatureLabel.topAnchor.constraint(equalTo: locationStackView.bottomAnchor, constant: 4),
            temperatureLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            weatherLabel.centerYAnchor.constraint(equalTo: temperatureLabel.centerYAnchor),
            weatherLabel.leadingAnchor.constraint(equalTo: temperatureLabel.trailingAnchor, constant: 8),
            
            // 세그먼트 컨트롤
            segmentedControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            segmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // 테이블뷰
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 로딩 인디케이터
            loadingIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        // 초기 데이터 설정
        locationLabel.text = "영등포구"
        temperatureLabel.text = "17°C"
        weatherLabel.text = "구름 조금"
    }
    
    func bind(to viewModel: MapViewModel) {
        self.viewModel = viewModel
        
        tableView.delegate = nil
        tableView.dataSource = nil
        
        // 로딩 상태 바인딩
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.tableView.isHidden = true
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.tableView.isHidden = false
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
        
        // 위치 정보 바인딩
        viewModel.locationTitle
            .observe(on: MainScheduler.instance)
            .bind(to: locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 데이터 로딩이 완료된 후에만 테이블뷰 바인딩
        viewModel.playgrounds
            .observe(on: MainScheduler.instance)
            .filter { _ in !viewModel.isLoading.value }
            .bind(to: tableView.rx.items(
                cellIdentifier: PlaygroundCell.identifier,
                cellType: PlaygroundCell.self
            )) { [weak self] index, playground, cell in
                if let userLocation = self?.locationManager.location {
                    let playgroundLocation = CLLocation(
                        latitude: playground.coordinate.latitude,
                        longitude: playground.coordinate.longitude
                    )
                    let distance = userLocation.distance(from: playgroundLocation) / 1000.0
                    cell.configure(with: playground, distance: distance)
                } else {
                    cell.configure(with: playground, distance: nil)
                }
            }
            .disposed(by: disposeBag)

        // 놀이터 선택 바인딩
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath: IndexPath) in
                guard let playground = self?.viewModel?.playgrounds.value[indexPath.row] else { return }
                NotificationCenter.default.post(
                    name: .playgroundSelected,
                    object: nil,
                    userInfo: ["playground": playground]
                )
            })
            .disposed(by: disposeBag)
        
        // 세그먼트 컨트롤 바인딩
        segmentedControl.rx.selectedSegmentIndex
            .map { index -> Set<String> in
                switch index {
                case 0: return ["전체"]
                case 1: return ["실내"]
                case 2: return ["실외"]
                default: return ["전체"]
                }
            }
            .bind(to: viewModel.categoriesSelected)
            .disposed(by: disposeBag)
    }
    
    func prepareForReuse() {
        viewModel = nil
    }
}

// MARK: - Extension for layout updates
extension PlaygroundListContent {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 세그먼트 컨트롤 모서리 둥글게
        segmentedControl.layer.cornerRadius = 8
        segmentedControl.layer.masksToBounds = true
        
        // 커스텀 구분선 추가
        if let hairline = headerView.layer.sublayers?.first(where: { $0.name == "hairline" }) {
            hairline.frame = CGRect(x: 0, y: headerView.bounds.height - 1, width: headerView.bounds.width, height: 1)
        } else {
            let hairline = CALayer()
            hairline.name = "hairline"
            hairline.frame = CGRect(x: 0, y: headerView.bounds.height - 1, width: headerView.bounds.width, height: 1)
            hairline.backgroundColor = UIColor.systemGray6.cgColor
            headerView.layer.addSublayer(hairline)
        }
    }
}
extension Notification.Name {
    static let playgroundSelected = Notification.Name("playgroundSelected")
}

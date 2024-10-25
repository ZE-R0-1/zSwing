//
//  RideDetailViewController.swift
//  zSwing
//
//  Created by USER on 10/25/24.
//

import UIKit
import CoreLocation

// MARK: - Models
struct RideInfo {
    let rideSn: String
    let installDate: String
    let facilityName: String
    let rideName: String
    let rideType: String
    let address: String
}

// MARK: - RideDetailViewController
class RideDetailViewController: UIViewController {
    private let rideInfo: RideInfo
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(rideInfo: RideInfo) {
        self.rideInfo = rideInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 놀이기구 이름
        let nameLabel = createLabel(text: rideInfo.rideName, font: .boldSystemFont(ofSize: 24))
        stackView.addArrangedSubview(nameLabel)
        
        // 시설 이름
        let facilityLabel = createLabel(text: rideInfo.facilityName, font: .systemFont(ofSize: 18), textColor: .gray)
        stackView.addArrangedSubview(facilityLabel)
        
        // 주소
        let addressLabel = createLabel(text: rideInfo.address, font: .systemFont(ofSize: 16), textColor: .darkGray)
        addressLabel.numberOfLines = 0
        stackView.addArrangedSubview(addressLabel)
        
        // 구분선
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)
        
        // 상세 정보
        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 8
        
        // 놀이기구 유형
        let typeLabel = createLabel(text: "놀이기구 유형: \(rideInfo.rideType)", font: .systemFont(ofSize: 16))
        detailsStack.addArrangedSubview(typeLabel)
        
        // 설치일
        let dateLabel = createLabel(text: "설치일: \(rideInfo.installDate)", font: .systemFont(ofSize: 16))
        detailsStack.addArrangedSubview(dateLabel)
        
        stackView.addArrangedSubview(detailsStack)
    }
    
    private func createLabel(text: String, font: UIFont, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
}

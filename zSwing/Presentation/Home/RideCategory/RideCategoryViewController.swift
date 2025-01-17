//
//  RideCategoryViewController.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit

class RideCategoryViewController: UIViewController {
    private let facility: PlaygroundFacility
    
    init(facility: PlaygroundFacility) {
        self.facility = facility
        super.init(nibName: nil, bundle: nil)
        title = facility.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        // 여기에 추가 UI 구성 코드 작성
    }
}

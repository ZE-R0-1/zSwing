//
//  RideCategoryViewController.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit
import RxSwift

class RideCategoryViewController: UIViewController {
    private let facility: PlaygroundFacility
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private let navigationStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "놀이터 찾기"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    // 오른쪽 여백을 위한 더미 뷰
    private let spacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    init(facility: PlaygroundFacility) {
        self.facility = facility
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 스택뷰에 컴포넌트 추가
        navigationStack.addArrangedSubview(backButton)
        navigationStack.addArrangedSubview(titleLabel)
        navigationStack.addArrangedSubview(spacerView)
        
        view.addSubview(navigationStack)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            navigationStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            navigationStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            navigationStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            navigationStack.heightAnchor.constraint(equalToConstant: 44),
            
            // 백 버튼 너비 설정
            backButton.widthAnchor.constraint(equalToConstant: 44),
            
            // 백 버튼에 leading padding 추가
            backButton.leadingAnchor.constraint(equalTo: navigationStack.leadingAnchor, constant: 8), // 이 줄 추가
            
            // 더미 뷰 너비를 백 버튼과 동일하게 설정
            spacerView.widthAnchor.constraint(equalTo: backButton.widthAnchor)
        ])
    }
    private func bindUI() {
        // 백 버튼 탭 이벤트 처리
        backButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

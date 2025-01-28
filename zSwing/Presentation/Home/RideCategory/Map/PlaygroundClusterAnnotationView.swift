//
//  PlaygroundClusterAnnotationView.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import MapKit

class PlaygroundClusterAnnotationView: MKAnnotationView {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white  // 기본 배경색을 흰색으로 변경
        view.layer.cornerRadius = 12   // cornerRadius를 12로 변경
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        return view
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = HomeViewModel.themeColor  // 텍스트 색상을 테마 색상으로 변경
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        containerView.frame = bounds
        addSubview(containerView)
        
        countLabel.frame = bounds
        containerView.addSubview(countLabel)
    }
    
    // MARK: - Configuration
    func configure(with count: Int) {
        countLabel.text = "\(count)"
        
        // 개수에 따라 크기 조절 (정사각형 유지)
        let size = count < 10 ? 40 : (count < 100 ? 50 : 60)
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        containerView.frame = bounds
        containerView.layer.cornerRadius = 12  // cornerRadius는 항상 12로 유지
        countLabel.frame = bounds
    }
    
    // MARK: - Selection Handling
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.containerView.transform = selected ?
                CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
                self.containerView.backgroundColor = selected ?
                HomeViewModel.themeColor : .white
                self.countLabel.textColor = selected ?
                    .white : HomeViewModel.themeColor
            }
        } else {
            containerView.transform = selected ?
            CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            containerView.backgroundColor = selected ?
            HomeViewModel.themeColor : .white
            countLabel.textColor = selected ?
                .white : HomeViewModel.themeColor
        }
    }
    
    // 재사용을 위한 초기화
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.transform = .identity
        containerView.backgroundColor = .white
        countLabel.textColor = HomeViewModel.themeColor
    }
}

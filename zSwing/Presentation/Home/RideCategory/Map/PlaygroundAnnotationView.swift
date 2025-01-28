//
//  PlaygroundAnnotationView.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import MapKit

class PlaygroundAnnotationView: MKAnnotationView {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = HomeViewModel.themeColor
        imageView.image = UIImage(systemName: "figure.play")
        return imageView
    }()
    
    // MARK: - Properties
    override var annotation: MKAnnotation? {
        didSet {
            clusteringIdentifier = "playground"
        }
    }
    
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
        
        imageView.frame = CGRect(x: 8, y: 8, width: 24, height: 24)
        containerView.addSubview(imageView)
        
        containerView.transform = .identity
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
                self.imageView.tintColor = selected ?
                    .white : HomeViewModel.themeColor
            }
        } else {
            containerView.transform = selected ?
            CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            containerView.backgroundColor = selected ?
            HomeViewModel.themeColor : .white
            imageView.tintColor = selected ?
                .white : HomeViewModel.themeColor
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.transform = .identity
        containerView.backgroundColor = .white
        imageView.tintColor = HomeViewModel.themeColor
    }
}

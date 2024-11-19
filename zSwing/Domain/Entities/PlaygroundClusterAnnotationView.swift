//
//  PlaygroundClusterAnnotationView.swift
//  zSwing
//
//  Created by USER on 11/19/24.
//

import UIKit
import MapKit

class PlaygroundClusterAnnotationView: MKAnnotationView {
    static let identifier = "PlaygroundClusterAnnotationView"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.2
        return view
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.image = UIImage(systemName: "figure.play")
        return imageView
    }()
    
    // MARK: - Properties
    private let markerSize: CGFloat = 40
    
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
        frame = CGRect(x: 0, y: 0, width: markerSize, height: markerSize)
        centerOffset = CGPoint(x: 0, y: -markerSize/2)
        canShowCallout = false
        
        containerView.frame = bounds
        addSubview(containerView)
        
        iconImageView.frame = CGRect(x: 4, y: 4, width: 20, height: 20)
        containerView.addSubview(iconImageView)
        
        countLabel.frame = CGRect(x: 22, y: 20, width: 24, height: 16)
        containerView.addSubview(countLabel)
        
        applyStyle(selected: false)
    }
    
    // MARK: - Style & Animation
    private func applyStyle(selected: Bool) {
        let backgroundColor: UIColor = selected ? .systemBlue.withAlphaComponent(0.9) : .systemBlue.withAlphaComponent(0.8)
        let shadowOpacity: Float = selected ? 0.4 : 0.2
        let shadowRadius: CGFloat = selected ? 6 : 4
        
        containerView.backgroundColor = backgroundColor
        containerView.layer.shadowOpacity = shadowOpacity
        containerView.layer.shadowRadius = shadowRadius
    }
    
    func animateSelection(selected: Bool) {
        UIView.animate(withDuration: 0.3,
                      delay: 0,
                      usingSpringWithDamping: 0.7,
                      initialSpringVelocity: 0.5,
                      options: .curveEaseInOut) {
            self.transform = selected ?
                CGAffineTransform(scaleX: 1.2, y: 1.2) :
                .identity
            self.applyStyle(selected: selected)
        }
    }
    
    // MARK: - Override Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        transform = .identity
        applyStyle(selected: false)
        countLabel.text = nil
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        if let cluster = annotation as? MKClusterAnnotation {
            let count = cluster.memberAnnotations.count
            countLabel.text = "+\(count)"
        }
        applyStyle(selected: isSelected)
    }
}

//
//  PostCell.swift
//  zSwing
//
//  Created by USER on 1/8/25.
//

import UIKit

protocol PostCellDelegate: AnyObject {
    func postCell(_ cell: PostCell, didTapLikeButton postId: String)
}

class PostCell: UICollectionViewCell {
    static let identifier = "PostCell"
    
    // MARK: - Properties
    private var post: Post?
    weak var delegate: PostCellDelegate?
    
    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .systemBackground
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .white
        control.pageIndicatorTintColor = .gray
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let likeButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        let image = UIImage(systemName: "heart", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupCollectionView()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        
        [profileImageView, usernameLabel, imageCollectionView, pageControl,
         likeButton, likeCountLabel, contentLabel].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Username
            usernameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            
            // Image Collection
            imageCollectionView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.7),
            
            // Page Control
            pageControl.centerXAnchor.constraint(equalTo: imageCollectionView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: -8),
            
            // Like Button
            likeButton.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 8),
            likeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Like Count
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            
            // Content Label
            contentLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    private func setupCollectionView() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        imageCollectionView.register(PostImageCell.self, forCellWithReuseIdentifier: PostImageCell.identifier)
    }
    
    private func setupActions() {
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func likeButtonTapped() {
        guard let post = post else { return }
        delegate?.postCell(self, didTapLikeButton: post.id)
    }
    
    // MARK: - Configuration
    func configure(with post: Post) {
        self.post = post
        
        usernameLabel.text = post.userName
        contentLabel.text = post.content
        likeCountLabel.text = "\(post.likeCount)"
        
        let heartImage = UIImage(systemName: post.isLiked ? "heart.fill" : "heart")
        likeButton.setImage(heartImage, for: .normal)
        likeButton.tintColor = post.isLiked ? .systemRed : .black
        
        pageControl.numberOfPages = post.imageUrls.count
        pageControl.isHidden = post.imageUrls.count <= 1
        
        imageCollectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension PostCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return post?.imageUrls.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostImageCell.identifier, for: indexPath) as? PostImageCell,
              let imageUrl = post?.imageUrls[indexPath.item] else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: imageUrl)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = page
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PostCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

//
//  ReviewWriteViewController.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import UIKit
import RxSwift
import RxCocoa
import PhotosUI

protocol ReviewWriteDelegate: AnyObject {
    func reviewWriteDidComplete()
}

class ReviewWriteViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: ReviewWriteViewModel
    private let disposeBag = DisposeBag()
    weak var delegate: ReviewWriteDelegate?
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 8
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private lazy var addImageButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        button.backgroundColor = .systemGray6
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var ratingView: RatingView = {
        let rating = RatingView()
        rating.translatesAutoresizingMaskIntoConstraints = false
        return rating
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .lightGray
        textView.text = "놀이터는 어떠셨나요? (최소 10자)"
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("작성 완료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        return gesture
    }()
    
    // MARK: - Initialization
    init(viewModel: ReviewWriteViewModel) {
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
        setupCollectionView()
        
        // 버튼 초기 상태 확인
        print("Initial submit button state - enabled: \(submitButton.isEnabled)")
        print("Initial submit button state - isUserInteractionEnabled: \(submitButton.isUserInteractionEnabled)")
        
        setupBindings()
        setupKeyboardDismiss()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "리뷰 작성"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        [addImageButton, imageCollectionView, ratingView, textView, submitButton].forEach {
            contentStackView.addArrangedSubview($0)
        }
        
        submitButton.addSubview(loadingIndicator)
        
        setupTextView()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            imageCollectionView.heightAnchor.constraint(equalToConstant: 100),
            addImageButton.heightAnchor.constraint(equalToConstant: 100),
            addImageButton.widthAnchor.constraint(equalToConstant: 100),
            
            textView.heightAnchor.constraint(equalToConstant: 150),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        imageCollectionView.register(
            ReviewImageCell.self,
            forCellWithReuseIdentifier: ReviewImageCell.identifier
        )
    }
    
    private func setupTextView() {
        textView.delegate = self
    }
    
    private func setupBindings() {
        // 이미지 추가 버튼 (기존 코드)
        addImageButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showImagePicker()
            })
            .disposed(by: disposeBag)
        
        // 선택된 이미지 표시 (기존 코드)
        viewModel.selectedImages
            .bind(to: imageCollectionView.rx.items(
                cellIdentifier: ReviewImageCell.identifier,
                cellType: ReviewImageCell.self
            )) { [weak self] index, image, cell in
                cell.configure(with: image)
                cell.deleteHandler = {
                    self?.viewModel.imageRemoved.accept(index)
                }
            }
            .disposed(by: disposeBag)
            
        // 별점 변경 (디버깅 추가)
        ratingView.ratingChanged
            .do(onNext: { rating in
                print("Rating changed to: \(rating)")
            })
            .bind(to: viewModel.ratingChanged)
            .disposed(by: disposeBag)
        
        // 텍스트 변경 (디버깅 추가)
        textView.rx.text.orEmpty
            .do(onNext: { text in
                print("Text changed. Length: \(text.count)")
            })
            .bind(to: viewModel.textChanged)
            .disposed(by: disposeBag)
        
        // 제출 버튼 활성화/비활성화 상태 (디버깅 추가)
        viewModel.isSubmitEnabled
            .do(onNext: { isEnabled in
                print("Submit button enabled: \(isEnabled)")
            })
            .bind(to: submitButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // 제출 버튼 탭 (디버깅 추가)
        submitButton.rx.tap
            .do(onNext: { _ in
                print("Submit button tapped!")
            })
            .bind(to: viewModel.submitTapped)
            .disposed(by: disposeBag)
        
        // 로딩 상태
        viewModel.isLoading
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        // 제출 완료
        viewModel.submitCompleted
            .subscribe(onNext: { [weak self] in
                print("Submit completed!")
                self?.delegate?.reviewWriteDidComplete()
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 에러 처리
        viewModel.error
            .subscribe(onNext: { [weak self] error in
                print("Error occurred: \(error.localizedDescription)")
                self?.showError(error)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helper Methods
    private func showImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = viewModel.canAddMoreImages.value ? 5 : 0
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "오류",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func setupKeyboardDismiss() {
        // 배경 탭 제스처 추가
        view.addGestureRecognizer(tapGesture)
        
        // Rx로 제스처 바인딩
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        
        // 키보드 표시/숨김에 따른 스크롤뷰 조정
        let keyboardWillShow = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return 0
                }
                return keyboardFrame.height
            }
        
        let keyboardWillHide = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        Observable.merge(keyboardWillShow, keyboardWillHide)
            .subscribe(onNext: { [weak self] height in
                guard let self = self else { return }
                let contentInset = UIEdgeInsets(
                    top: 0,
                    left: 0,
                    bottom: height,
                    right: 0
                )
                self.scrollView.contentInset = contentInset
                self.scrollView.scrollIndicatorInsets = contentInset
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UITextViewDelegate
extension ReviewWriteViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "놀이터는 어떠셨나요? (최소 10자)"
            textView.textColor = .lightGray
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ReviewWriteViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProviders = results.map(\.itemProvider)
        var images: [UIImage] = []
        
        let group = DispatchGroup()
        
        itemProviders.forEach { provider in
            group.enter()
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    defer { group.leave() }
                    if let image = image as? UIImage {
                        images.append(image)
                    }
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.viewModel.imagesSelected.accept(images)
        }
    }
}

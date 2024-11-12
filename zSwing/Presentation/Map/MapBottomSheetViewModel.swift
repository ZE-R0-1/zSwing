//
//  MapBottomSheetViewModel.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import RxSwift
import RxCocoa
import Foundation
import RxGesture

class MapBottomSheetViewModel {
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let itemSelected = PublishRelay<IndexPath>()
    
    // MARK: - Outputs
    let items = BehaviorRelay<[String]>(value: ["Section 1", "Section 2", "Section 3"])
    let dismissTrigger = PublishRelay<Void>()
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                // Handle item selection
                print("Selected item at index: \(indexPath.row)")
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    func loadData() {
        // Load data from repository if needed
        // items.accept(newItems)
    }
}

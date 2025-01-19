//
//  RideCategoryViewModel.swift
//  zSwing
//
//  Created by USER on 1/19/25.
//

import RxSwift
import RxRelay

class RideCategoryViewModel {
    // Input
    private let facility: PlaygroundFacility
    
    // Output
    let categories = BehaviorRelay<[String]>(value: PlaygroundFacilityType.allCases.map { $0.rawValue })
    let selectedIndex: BehaviorRelay<Int>
    
    init(facility: PlaygroundFacility) {
        self.facility = facility
        // 선택된 facility에 해당하는 인덱스 찾기
        let index = PlaygroundFacilityType.allCases.firstIndex { $0.rawValue == facility.name } ?? 0
        self.selectedIndex = BehaviorRelay<Int>(value: index)
    }
    
    func categorySelected(at index: Int) {
        selectedIndex.accept(index)
        // 여기에 카테고리 선택에 따른 추가 비즈니스 로직 구현 가능
    }
}

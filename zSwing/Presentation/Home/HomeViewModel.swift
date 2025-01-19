//
//  HomeViewModel.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit
import RxSwift
import RxCocoa

class HomeViewModel {
    private let coordinator: HomeCoordinator
    
    // 기존 코드 유지
    static let themeColor = UIColor(red: 38/255, green: 222/255, blue: 129/255, alpha: 1.0)
    let userName = BehaviorRelay<String>(value: "홍길동")
    
    init(coordinator: HomeCoordinator) {
        self.coordinator = coordinator
    }
    
    func didSelectFacility(_ facility: PlaygroundFacility) {
        coordinator.showRideCategory(for: facility)
    }
    
    var welcomeMessage: Observable<NSAttributedString> {
        return userName.map { [weak self] name in
            let fullText = "\(name)님, 반가워요!\n놀이터를 찾아볼까요?"
            let attributedString = NSMutableAttributedString(string: fullText)
            
            // 사용자 이름 부분에만 컬러 적용
            let range = (fullText as NSString).range(of: name)
            attributedString.addAttribute(.foregroundColor,
                                        value: HomeViewModel.themeColor,
                                        range: range)
            
            // 전체 텍스트에 폰트 적용
            let fullRange = NSRange(location: 0, length: fullText.count)
            attributedString.addAttribute(.font,
                                        value: UIFont.systemFont(ofSize: 24, weight: .bold),
                                        range: fullRange)
            
            return attributedString
        }
    }
    
    let facilities = BehaviorRelay<[PlaygroundFacility]>(value:
        PlaygroundFacilityType.allCases.map { PlaygroundFacility(type: $0) }
    )
}

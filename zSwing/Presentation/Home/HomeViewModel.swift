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
    // 놀이터 테마 컬러 - 밝은 하늘색
    static let themeColor = UIColor(red: 38/255, green: 222/255, blue: 129/255, alpha: 1.0) // #26DE81

    let userName = BehaviorRelay<String>(value: "홍길동")
    
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
    
    let facilities = BehaviorRelay<[PlaygroundFacility]>(value: [
        PlaygroundFacility(name: "그네", imageName: "arrow.up.and.down"),
        PlaygroundFacility(name: "미끄럼틀", imageName: "arrow.down.forward.circle.fill"),
        PlaygroundFacility(name: "정글짐", imageName: "cube.transparent"),
        PlaygroundFacility(name: "공중기구", imageName: "airplane"),
        PlaygroundFacility(name: "회전기구", imageName: "rotate.3d"),
        PlaygroundFacility(name: "흔들기구", imageName: "wave.3.right"),
        PlaygroundFacility(name: "오르는기구", imageName: "arrow.up.circle"),
        PlaygroundFacility(name: "건너는기구", imageName: "arrow.left.and.right"),
        PlaygroundFacility(name: "조합놀이대", imageName: "square.stack.3d.up"),
        PlaygroundFacility(name: "철봉", imageName: "figure.gymnastics"),
        PlaygroundFacility(name: "늑목", imageName: "arrow.up.and.down.square"),
        PlaygroundFacility(name: "평균대", imageName: "minus")
    ])
}

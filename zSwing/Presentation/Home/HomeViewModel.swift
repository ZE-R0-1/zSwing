//
//  HomeViewModel.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit

class HomeViewModel {
    // 놀이터 테마 컬러 - 밝은 하늘색
    static let themeColor = UIColor(red: 38/255, green: 222/255, blue: 129/255, alpha: 1.0) // #26DE81

    var userName: String {
        return "홍길동"
    }
    
    var welcomeMessage: NSAttributedString {
        let fullText = "\(userName)님, 반가워요!\n놀이터를 찾아볼까요?"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // 사용자 이름 부분에만 컬러 적용
        let range = (fullText as NSString).range(of: userName)
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

//
//  BottomSheetUseCase.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import RxSwift
import CoreLocation

enum SheetHeight {
    case min, mid, max
    
    var heightPercentage: CGFloat {
        switch self {
        case .min: return 0.1
        case .mid: return 0.465
        case .max: return 0.9
        }
    }
}

protocol BottomSheetUseCase {
    func getCurrentSheetHeight() -> SheetHeight
    func calculateNextSheetHeight(
        currentHeight: CGFloat,
        screenHeight: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) -> SheetHeight
    func shouldAllowScroll(at sheetHeight: SheetHeight) -> Bool
    func validateSheetHeight(_ height: CGFloat, screenHeight: CGFloat) -> CGFloat
}

final class DefaultBottomSheetUseCase: BottomSheetUseCase {
    private let minVelocityForFling: CGFloat = 1500
    private let heightThresholds = (min: 0.3, max: 0.75)
    
    func getCurrentSheetHeight() -> SheetHeight {
        return .mid  // 기본값
    }
    
    func calculateNextSheetHeight(
        currentHeight: CGFloat,
        screenHeight: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) -> SheetHeight {
        let currentHeightPercentage = currentHeight / screenHeight
        
        // 빠른 스와이프 처리
        if abs(velocity) > minVelocityForFling {
            return velocity > 0 ? .min : .max
        }
        
        // 일반적인 드래그 처리
        if currentHeightPercentage < heightThresholds.min {
            return .min
        } else if currentHeightPercentage < heightThresholds.max {
            return .mid
        } else {
            return .max
        }
    }
    
    func shouldAllowScroll(at sheetHeight: SheetHeight) -> Bool {
        return sheetHeight == .max
    }
    
    func validateSheetHeight(_ height: CGFloat, screenHeight: CGFloat) -> CGFloat {
        let maxHeight = screenHeight * SheetHeight.max.heightPercentage
        let minHeight = screenHeight * SheetHeight.min.heightPercentage
        return min(max(height, minHeight), maxHeight)
    }
}

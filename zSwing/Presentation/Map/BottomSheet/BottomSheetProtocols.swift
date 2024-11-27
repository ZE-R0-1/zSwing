//
//  BottomSheetProtocols.swift
//  zSwing
//
//  Created by USER on 11/26/24.
//

import UIKit

protocol BottomSheetContent: UIView {
    var contentScrollView: UIScrollView? { get }
    func prepareForReuse()
}

protocol BottomSheetDelegate: AnyObject {
    func bottomSheet(_ sheet: CustomBottomSheetView, didSelectContent content: BottomSheetContent)
    func bottomSheet(_ sheet: CustomBottomSheetView, heightDidChange height: CGFloat)
}

enum BottomSheetContentType {
    case playgroundList
    case playgroundDetail(Playground)
}

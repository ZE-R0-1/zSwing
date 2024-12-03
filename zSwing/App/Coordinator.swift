//
//  Coordinator.swift
//  zSwing
//
//  Created by USER on 12/2/24.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

protocol CoordinatorDelegate: AnyObject {
    func didFinish(coordinator: Coordinator)
}

//
//  CoordinatorType.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

/// Protocol used for coordinator pattern implementation
protocol CoordinatorType {
    var presenter: UINavigationController { get set }
    var onDidStop: (() -> Void)? { get set }
    func start(_ presentFrom: UIViewController?)
    func stop()
}

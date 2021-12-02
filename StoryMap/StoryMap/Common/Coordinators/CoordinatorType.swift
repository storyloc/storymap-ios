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
	
	func start()
	func showAlert(with config: AlertConfig)
}

extension CoordinatorType {
	func showAlert(with config: AlertConfig) {
		let alertController = config.controller
		
		if let presentedController = presenter.viewControllers.last?.presentedViewController {
			presentedController.present(alertController, animated: true)
			return
		}
		
		presenter.present(alertController, animated: true)
	}
}

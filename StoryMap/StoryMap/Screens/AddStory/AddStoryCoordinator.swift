//
//  AddStoryCoordinator.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

class AddStoryCoordinator: CoordinatorType {

    var presenter = UINavigationController()
    
    var onDidStop: (() -> Void)?
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = AddStoryViewModel()
        viewModel.onShowAlert = { [weak self] alert in
            self?.presenter.present(alert, animated: true)
        }
        let viewController = AddStoryViewController(viewModel: viewModel)
        presenter.viewControllers = [viewController]
        presentFrom?.present(presenter, animated: true)
    }
    
    func stop() {
        
    }
    
    
}

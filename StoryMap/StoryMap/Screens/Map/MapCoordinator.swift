//
//  MapCoordinator.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

class MapCoordinator: CoordinatorType {
    var presenter = UINavigationController()
    
    var addStoryCoordinator: CoordinatorType?
    
    var onDidStop: (() -> Void)?
    
    func start(_ presentFrom: UIViewController?) {
        let viewController = MapViewController()
        viewController.onAddStory = { [weak self] in
            self?.showAddStory()
        }
        presenter.pushViewController(viewController, animated: true)
    }
    
    func stop() {
        presenter.popViewController(animated: true)
    }
    
    private func showAddStory() {
        addStoryCoordinator = AddStoryCoordinator()
        addStoryCoordinator?.start(presenter.topViewController)
    }
}

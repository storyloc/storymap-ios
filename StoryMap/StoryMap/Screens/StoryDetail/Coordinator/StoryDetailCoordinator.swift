//
//  StoryDetailCoordinator.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import UIKit

class StoryDetailCoordinator: CoordinatorType {
    var presenter = UINavigationController()
    var onDidStop: (() -> Void)?
    
    var story: Story
    
    init(story: Story) {
        self.story = story
    }
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = StoryDetailViewModel(story: story)
        viewModel.onClose = { [weak self] in
            self?.stop()
        }
        
        let viewController = StoryDetailViewController(viewModel: viewModel)
        presenter.pushViewController(viewController, animated: true)
    }
    
    func stop() {
        presenter.popViewController(animated: true)
    }
}

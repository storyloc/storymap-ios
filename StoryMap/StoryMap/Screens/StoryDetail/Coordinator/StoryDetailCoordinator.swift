//
//  StoryDetailCoordinator.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import UIKit
import Combine

class StoryDetailCoordinator: CoordinatorType {
	var presenter: UINavigationController
	var story: Story
	
	private var subscribers = Set<AnyCancellable>()
    
    init(presenter: UINavigationController, story: Story) {
		self.presenter = presenter
        self.story = story
    }
    
    func start() {
        let viewModel = StoryDetailViewModel(story: story)
		
		viewModel.closeSubject
			.sink { [weak self] in
				self?.stop()
			}
			.store(in: &subscribers)
        
        let viewController = StoryDetailViewController(viewModel: viewModel)
        presenter.pushViewController(viewController, animated: true)
    }
    
    func stop() {
        presenter.popViewController(animated: true)
    }
}

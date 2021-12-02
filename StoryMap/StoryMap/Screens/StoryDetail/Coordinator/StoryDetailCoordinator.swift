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
	
	var deleteStorySubject = PassthroughSubject<Story, Never>()
	
	private var subscribers = Set<AnyCancellable>()
    
    init(presenter: UINavigationController, story: Story) {
		self.presenter = presenter
        self.story = story
    }
    
    func start() {
        let viewModel = StoryDetailViewModel(story: story)
		
		viewModel.deleteStorySubject
			.sink { [weak self] story in
				self?.deleteStorySubject.send(story)
				self?.stop()
			}
			.store(in: &subscribers)
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

//
//  DebugCoordinator.swift
//  StoryMap
//
//  Created by Felix Böhm on 28.11.21.
//

import UIKit
import Combine

class StoryListCoordinator: CoordinatorType {
    var addStoryCoordinator: AddStoryCoordinator?
    var storyDetailCoordinator: StoryDetailCoordinator?

    var presenter = UINavigationController()
	
	private var subscribers = Set<AnyCancellable>()

    func start(_ presentFrom: UIViewController?) {
        let viewModel = StoryListViewModel()
        let viewController = StoryListViewController(
            viewModel: viewModel,
            locationManager: LocationManager() // Maybe share the instance with Map View?
        )
		
		viewModel.addStorySubject
			.sink { [weak self] location in
				self?.showAddStory(with: location)
			}
			.store(in: &subscribers)
		viewModel.openStorySubject
			.sink { [weak self] story in
				self?.showStoryDetail(with: story)
			}
			.store(in: &subscribers)

        viewController.modalPresentationStyle = .fullScreen
        presenter.pushViewController(viewController, animated: true)
    }

    func stop() {
        presenter.popViewController(animated: true)
    }

    private func showAddStory(with location: Location) {
        addStoryCoordinator = AddStoryCoordinator(location: location)
		addStoryCoordinator?.showStorySubject
			.sink { [weak self] story in
				self?.showStoryDetail(with: story)
			}
			.store(in: &subscribers)
        
        addStoryCoordinator?.start(presenter.topViewController)
    }

    private func showStoryDetail(with story: Story) {
        storyDetailCoordinator = StoryDetailCoordinator(story: story)
        storyDetailCoordinator?.presenter = presenter
        storyDetailCoordinator?.start(nil)
    }
}
    

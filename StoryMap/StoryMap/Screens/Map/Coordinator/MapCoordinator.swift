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
    
    var addStoryCoordinator: AddStoryCoordinator?
    var storyDetailCoordinator: StoryDetailCoordinator?
    
    var onDidStop: (() -> Void)?
	
	private var onDeleteStory: ((Story) -> Void)?
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = MapViewModel()
        let viewController = MapViewController(
            viewModel: viewModel,
            locationManager: LocationManager()
        )
        viewController.modalPresentationStyle = .fullScreen
        viewModel.onAddStory = { [weak self] location in
            self?.showAddStory(with: location)
        }
        viewModel.onOpenStory = { [weak self] story in
            self?.showStoryDetail(with: story)
        }
		
		onDeleteStory = viewModel.storyDeleted
        presenter.pushViewController(viewController, animated: true)
    }
    
    func stop() {
        presenter.popViewController(animated: true)
    }
    
    private func showAddStory(with location: Location) {
        addStoryCoordinator = AddStoryCoordinator(location: location)
        addStoryCoordinator?.onShowStory = { [weak self] story in
            self?.showStoryDetail(with: story)
        }
        addStoryCoordinator?.start(presenter.topViewController)
    }
    
    private func showStoryDetail(with story: Story) {
        storyDetailCoordinator = StoryDetailCoordinator(story: story)
		storyDetailCoordinator?.onDeleteStory = { [weak self] story in
			self?.onDeleteStory?(story)
		}
        storyDetailCoordinator?.presenter = presenter
        storyDetailCoordinator?.start(nil)
    }
}

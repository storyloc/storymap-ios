//
//  DebugCoordinator.swift
//  StoryMap
//
//  Created by Felix Böhm on 28.11.21.
//

import Foundation
import UIKit

class StoryListCoordinator: CoordinatorType {
    var onDidStop: (() -> Void)?

    var addStoryCoordinator: AddStoryCoordinator?
    var storyDetailCoordinator: StoryDetailCoordinator?

    var presenter = UINavigationController()

    func start(_ presentFrom: UIViewController?) {
        let viewModel = StoryListViewModel()
        let viewController = StoryListViewController(
            viewModel: viewModel,
            locationManager: LocationManager() // Maybe share the instance with Map View?
        )
        viewModel.onClose = { [weak self] in
            self?.stop()
        }
        viewModel.onAddStory = { [weak self] location in
            self?.showAddStory(with: location)
        }
        viewModel.onOpenStory = { [weak self] story in
            self?.showStoryDetail(with: story)
        }

        viewController.modalPresentationStyle = .fullScreen
        presenter.pushViewController(viewController, animated: true)
    }

    func stop() {
        presenter.popViewController(animated: true)
    }

    private func showAddStory(with location: Location) {
        addStoryCoordinator = AddStoryCoordinator(location: location, simple: false)
        addStoryCoordinator?.onShowStory = { [weak self] story in
            self?.showStoryDetail(with: story)
        }
        addStoryCoordinator?.start(presenter.topViewController)
    }

    private func showStoryDetail(with story: Story) {
        storyDetailCoordinator = StoryDetailCoordinator(story: story)
        storyDetailCoordinator?.onDeleteStory = { story in
            logger.info("StoryList: Delete \(story)")
        }
        storyDetailCoordinator?.presenter = presenter
        storyDetailCoordinator?.start(nil)
    }
}
    

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
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = MapViewModel()
        let viewController = MapViewController(viewModel: viewModel)
        viewModel.onAddStory = { [weak self] in
            self?.showAddStory()
        }
        presenter.pushViewController(viewController, animated: true)

        // For testing purpose only
        setupTestStory()
    }
    
    func stop() {
        presenter.popViewController(animated: true)
    }
    
    private func showAddStory() {
        addStoryCoordinator = AddStoryCoordinator()
        addStoryCoordinator?.onShowStory = { [weak self] story in
            self?.showStoryDetail(with: story)
        }
        addStoryCoordinator?.start(presenter.topViewController)
    }
    
    private func showStoryDetail(with story: Story) {
        storyDetailCoordinator = StoryDetailCoordinator(story: story)
        storyDetailCoordinator?.presenter = presenter
        storyDetailCoordinator?.start(nil)
    }

    private func setupTestStory() {
        let store = RealmDataProvider.shared
        let title: String? = "Lulu Waterfall"
        let image = StyleKit.image.make(
            from: StyleKit.image.examples.waterfall,
            with: .alwaysTemplate
        )

        let imageData = image?.jpegData(compressionQuality: 1)
        guard let title = title, let imageData = imageData else {
            return
        }

        let story = Story(title: title, image: imageData)
        store.write(object: story)

        showStoryDetail(with: story)
    }
}

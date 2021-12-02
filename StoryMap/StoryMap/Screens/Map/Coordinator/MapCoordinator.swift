//
//  MapCoordinator.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit
import Combine

class MapCoordinator: CoordinatorType {
    var presenter = UINavigationController()
    
    var storyDetailCoordinator: StoryDetailCoordinator?
    var storyListCoordinator: StoryListCoordinator?
	
	private var deleteStorySubject: PassthroughSubject<Story, Never>?
	
	private let photoManager = PhotoInputManager()
	private var subscribers = Set<AnyCancellable>()
	
	private var photoManagerSubscriber: AnyCancellable?
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = MapViewModel()
        let viewController = MapViewController(
            viewModel: viewModel,
            locationManager: LocationManager()
        )
        viewController.modalPresentationStyle = .fullScreen
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
        viewModel.openStoryListSubject
			.sink { [weak self] in
				self?.showStoryList()
			}
			.store(in: &subscribers)
		
		deleteStorySubject = viewModel.storyDeletedSubject
        presenter.pushViewController(viewController, animated: true)
    }
    
    private func showAddStory(with location: Location) {
		if photoManagerSubscriber != nil {
			photoManagerSubscriber?.cancel()
			photoManagerSubscriber = nil
		}
		
		photoManagerSubscriber = photoManager.imageSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] image in
				StoryDataProvider.shared.createStory(
					from: image,
					and: location
				)
				self?.presenter.dismiss(animated: true)
			}
		
		let viewController = photoManager.makeViewController(with: .camera)
		presenter.present(viewController, animated: true)
    }
    
    private func showStoryDetail(with story: Story) {
		if storyDetailCoordinator != nil {
			storyDetailCoordinator = nil
		}
		
        storyDetailCoordinator = StoryDetailCoordinator(story: story)
		storyDetailCoordinator?.deleteStorySubject
			.sink { [weak self] story in
				self?.deleteStorySubject?.send(story)
			}
			.store(in: &subscribers)
        storyDetailCoordinator?.presenter = presenter
        storyDetailCoordinator?.start(nil)
    }

    private func showStoryList() {
		if storyListCoordinator != nil {
			storyListCoordinator = nil
		}
		
        storyListCoordinator = StoryListCoordinator()
        storyListCoordinator?.presenter = presenter
        storyListCoordinator?.start(nil)
    }
}

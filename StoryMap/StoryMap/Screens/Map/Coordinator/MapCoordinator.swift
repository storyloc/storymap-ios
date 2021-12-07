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
	var presenter: UINavigationController
    
    var storyDetailCoordinator: StoryDetailCoordinator?
    var storyListCoordinator: StoryListCoordinator?
	
	private let photoManager = PhotoInputManager()
	private var subscribers = Set<AnyCancellable>()
	
	private var photoManagerSubscriber: AnyCancellable?
	
	init(presenter: UINavigationController) {
		self.presenter = presenter
	}
    
    func start() {
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
		
        presenter.pushViewController(viewController, animated: true)
    }
    
    private func showAddStory(with location: Location) {
		photoManagerSubscriber = photoManager.resultSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] result in
				StoryDataProvider.shared.createStory(
					from: result.image,
					and: location
				)
				self?.presenter.dismiss(animated: true)
				
				self?.photoManagerSubscriber?.cancel()
				self?.photoManagerSubscriber = nil
			}
		
		let viewController = photoManager.makeViewController(with: .camera)
		presenter.present(viewController, animated: true)
    }
    
    private func showStoryDetail(with story: Story) {
		if storyDetailCoordinator != nil {
			storyDetailCoordinator = nil
		}
		
		storyDetailCoordinator = StoryDetailCoordinator(presenter: presenter, story: story)
        storyDetailCoordinator?.start()
    }

    private func showStoryList() {
		if storyListCoordinator != nil {
			storyListCoordinator = nil
		}
		
        storyListCoordinator = StoryListCoordinator(presenter: presenter)
        storyListCoordinator?.start()
    }
}

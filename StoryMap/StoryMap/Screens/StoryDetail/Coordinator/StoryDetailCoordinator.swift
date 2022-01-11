//
//  StoryDetailCoordinator.swift
//  StoryMap
//
//  Created by Dory on 11/01/2022.
//

import UIKit
import Combine

final class StoryDetailCoordinator: CoordinatorType {
	var presenter: UINavigationController
	
	private var story: Story
	private var subscribers = Set<AnyCancellable>()
	
	private let photoManager = PhotoInputManager()
	private var photoManagerSubscriber: AnyCancellable?
	
	private let storyDataProvider = StoryDataProvider.shared
	
	init(presenter: UINavigationController, story: Story) {
		self.presenter = presenter
		self.story = story
	}
	
	func start() {
		let viewModel = StoryDetailViewModel(story: story)
		
		viewModel.addStoryPointSubject
			.sink { [weak self] type in
				self?.showAddStoryPoint(for: type)
			}
			.store(in: &subscribers)
		
		viewModel.closeSubject
			.sink { [weak self] _ in
				self?.presenter.popViewController(animated: true)
			}
			.store(in: &subscribers)
		
		viewModel.showAlertSubject
			.sink { [weak self] config in
				self?.showAlert(with: config)
			}
			.store(in: &subscribers)
		
		let viewController = StoryDetailViewController(viewModel: viewModel)
		presenter.pushViewController(viewController, animated: true)
	}
	
	private func showAddStoryPoint(for type: PhotoInputManager.SourceType) {
		photoManagerSubscriber = photoManager.resultSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] result in
				guard let self = self else { return }
				
				if let storyPoint = self.storyDataProvider.createStoryPoint(from: result) {
					self.storyDataProvider.add(storyPoint: storyPoint, to: self.story)
				}
				
				self.presenter.dismiss(animated: true)
				
				self.photoManagerSubscriber?.cancel()
				self.photoManagerSubscriber = nil
			}
		
		let viewController = photoManager.makeViewController(with: type)
		presenter.present(viewController, animated: true)
	}
}

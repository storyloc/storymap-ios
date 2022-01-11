//
//  AddStoryCoordinator.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import UIKit
import PhotosUI
import Combine

final class AddStoryCoordinator: CoordinatorType {
	var presenter: UINavigationController
	
	var showStorySubject = PassthroughSubject<Story, Never>()
	
	private var subscribers = Set<AnyCancellable>()
	
	init(presenter: UINavigationController) {
		self.presenter = presenter
	}
	
	func start() {
		let viewModel = AddStoryViewModel()
		let viewController = AddStoryViewController(viewModel: viewModel)
		viewController.isModalInPresentation = true
		
		setupSubscribers(from: viewModel)
		
		presenter.present(viewController, animated: true)
	}
	
	func stop() {
		presenter.visibleViewController?.dismiss(animated: true, completion: nil)
	}
	
	private func setupSubscribers(from viewModel: AddStoryViewModel) {
		viewModel.showAlertSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] config in
				self?.showAlert(with: config)
			}
			.store(in: &subscribers)
		
		viewModel.closeSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] in
				self?.stop()
			}
			.store(in: &subscribers)
		
		viewModel.confirmSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] story in
				guard let self = self else { return }
				self.stop(story: story)
			}
			.store(in: &subscribers)
	}
	
	func stop(story: Story?) {
		presenter.visibleViewController?.dismiss(animated: true, completion: { [weak self] in
			if let story = story {
				self?.showStorySubject.send(story)
			}
		})
	}
}

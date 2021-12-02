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
	
	private var location: Location
	
	private let photoManager = PhotoInputManager()
	private var subscribers = Set<AnyCancellable>()
    
    init(presenter: UINavigationController, location: Location) {
		self.presenter = presenter
        self.location = location
    }
    
    func start() {
        let viewModel = AddStoryViewModel(location: location)
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
		
		viewModel.addImageSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] type in
				self?.showAddImage(with: type)
			}
			.store(in: &subscribers)
		
		viewModel.confirmSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] story in
				guard let self = self else { return }
				self.stop(story: story)
			}
			.store(in: &subscribers)
		
		photoManager.imageSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self, weak viewModel] image in
				self?.presenter.dismiss(animated: true)
				viewModel?.image = image.jpegData(compressionQuality: 0.0)
			}
			.store(in: &subscribers)
	}
	
	private func showAddImage(with type: PhotoInputManager.SourceType) {
		let viewController = photoManager.makeViewController(with: type)
		presenter.present(viewController, animated: true, completion: nil)
	}
    
    func stop(story: Story?) {
        presenter.visibleViewController?.dismiss(animated: true, completion: { [weak self] in
            if let story = story {
				self?.showStorySubject.send(story)
            }
        })
    }
}

//
//  StoryPointDetailCoordinator.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import UIKit
import Combine

class StoryPointDetailCoordinator: CoordinatorType {
	var presenter: UINavigationController
	var storyPoint: StoryPoint
	
	private var subscribers = Set<AnyCancellable>()
    
    init(presenter: UINavigationController, storyPoint: StoryPoint) {
		self.presenter = presenter
        self.storyPoint = storyPoint
    }
    
    func start() {
        let viewModel = StoryPointDetailViewModel(storyPoint: storyPoint)
		
		viewModel.closeSubject
			.sink { [weak self] in
				self?.stop()
			}
			.store(in: &subscribers)
        
        let viewController = StoryPointDetailViewController(viewModel: viewModel)
        presenter.pushViewController(viewController, animated: true)
    }
    
    func stop() {
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
		
        presenter.popViewController(animated: true)
    }
}

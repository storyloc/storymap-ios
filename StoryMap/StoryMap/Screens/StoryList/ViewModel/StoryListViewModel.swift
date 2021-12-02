//
//  DebugViewModel.swift
//  StoryMap
//
//  Created by Felix Böhm on 28.11.21.
//

import Foundation
import RealmSwift
import SwiftUI
import Combine

final class StoryListViewModel {
    
    // MARK: - Public properties
	
	var addStorySubject = PassthroughSubject<Location, Never>()
	var openStorySubject = PassthroughSubject<Story, Never>()
    
    @Published var stories: [Story] = []
    
    var location: Location? {
        didSet {
            guard oldValue == nil else {
                return
            }
            logger.info("StoryListVM: location didSet")
        }
    }

    // MARK: - Private properties
    
    private let storyDataProvider = StoryDataProvider.shared
	private var subscribers = Set<AnyCancellable>()

    init() {
        setupSubscribers()
    }
	
	deinit {
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
	}

    func openStory(with index: Int) {
        logger.info("StoryListVM: open Story \(index)")
		openStorySubject.send(stories[index])
    }

    func addStory(with location: Location) {
        logger.info("StoryListVM: addStory")
		addStorySubject.send(location)
    }

    // MARK: - Private methods
    
    private func setupSubscribers() {
		storyDataProvider.$stories
			.sink { [weak self] data in
				self?.stories = data
			}
			.store(in: &subscribers)
    }
    
    private func updateStories(with results: Results<Story>) {
        self.stories = results.toArray(ofType: Story.self)
    }
}

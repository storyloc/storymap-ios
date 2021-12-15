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
    var storiesChangedSubject = PassthroughSubject<Void, Never>()
    
    var stories: [Story] {
        get {
            storyDataProvider.stories
        }
    }
    
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
		storyDataProvider.storyUpdateSubject
			.sink { [weak self] _ in
                self?.storiesChangedSubject.send()
			}
			.store(in: &subscribers)
    }
}

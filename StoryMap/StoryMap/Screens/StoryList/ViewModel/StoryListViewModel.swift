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
    
	@Published var tableContent: [StoryListCell.Content] = []
    
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
		tableContent = makeContent(from: storyDataProvider.stories)
    }
	
	deinit {
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
	}

    func openStory(with index: Int) {
        logger.info("StoryListVM: open Story \(index)")
		openStorySubject.send(storyDataProvider.stories[index])
    }

    func addStory(with location: Location) {
        logger.info("StoryListVM: addStoryPoint")
		addStorySubject.send(location)
    }

    // MARK: - Private methods
    
    private func setupSubscribers() {
		storyDataProvider.storyUpdateSubject
			.sink { [weak self] _ in
				guard let self = self else { return }
				self.tableContent = self.makeContent(from: self.storyDataProvider.stories)
			}
			.store(in: &subscribers)
    }
	
	private func makeContent(from stories: [Story]) -> [StoryListCell.Content] {
		stories.map { story in
			StoryListCell.Content(
				title: story.title,
				image: story.mainImage,
				tagContent: makeTagContent(for: story)
			)
		}
	}
	
	private func makeTagContent(for story: Story) -> [TagButton.Content] {
		story.allTags.map { tag in
			TagButton.Content(
				title: tag.localizedTitle,
				isSelected: true,
				action: nil
			)
		}
	}
}

//
//  MapViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import RealmSwift
import Combine
import UIKit

class MapViewModel: ObservableObject {
	@Published var collectionData: [MapCollectionData] = []
	@Published var filterContent: [TagButton.Content] = []
	
	let addStoryPointSubject = PassthroughSubject<Story, Never>()
	let openStorySubject = PassthroughSubject<Story, Never>()
	let openStoryListSubject = PassthroughSubject<Void, Never>()
	
	var storyInsertedSubject = PassthroughSubject<Story?, Never>()
	
	@Published private var stories: [Story] = []
	@Published private var activeFilters: [Tag] = []
	
	private let audioRecorder = AudioRecorder()
	private var subscribers = Set<AnyCancellable>()
	
	private var allTags: [Tag] = []
	
	private var currentlyPlaying: Story? {
		didSet {
			for (i, cell) in collectionData.enumerated() {
				collectionData[i].cell.isPlaying = currentlyPlaying?.id.stringValue == cell.location.cid
			}
		}
	}
	
	var location: Location? {
		didSet {
			guard oldValue == nil else {
				return
			}
			
			updateStories(with: stories)
			
			logger.info("MapVM:location didSet, start sorting")
		}
	}
	
	private let storyDataProvider = StoryDataProvider.shared
	
	init() {
		setupSubscribers()
	}
	
	func openStory(with index: Int) {
		audioRecorder.stopPlaying()
		openStorySubject.send(stories[index])
	}
	
	func addStoryPoint(with index: Int) {
		Configuration.isSimulator ? addTestStory() : addStoryPointSubject.send(stories[index])
		audioRecorder.stopPlaying()
	}
	
	func openStoryList() {
		audioRecorder.stopPlaying()
		openStoryListSubject.send()
	}
	
	private func setupSubscribers() {
		$stories
			.sink { [weak self] stories in
				self?.collectionData = self?.makeCollectionData(from: stories) ?? []
			}
			.store(in: &subscribers)
		
		$activeFilters
			.sink { [weak self] filters in
				self?.filterStories(with: filters)
			}
			.store(in: &subscribers)
		
		audioRecorder.$currentlyPlaying
			.sink { [weak self] rec in
				self?.currentlyPlaying = rec?.storyPoint.first?.story.first
			}
			.store(in: &subscribers)
		
		storyDataProvider.storyUpdateSubject
			.sink { [weak self] update in
				switch update {
				case .initial(stories: let stories):
					self?.updateStories(with: stories)
				case .inserted(stories: let stories, insertedStory: let story):
					self?.updateStories(with: stories)
					self?.storyInsertedSubject.send(story)
				}
			}
			.store(in: &subscribers)
	}
	
	private func makeCollectionData(from stories: [Story]) -> [MapCollectionData] {
		return stories.map { story in
			makeCollectionData(for: story)
		}
	}
	
	private func makeCollectionData(for story: Story) -> MapCollectionData {
		var action: (() -> Void)?
		
		if !story.allRecordings.isEmpty {
			action = { [weak self] in
				guard let self = self else { return }
				
				self.audioRecorder.currentlyPlaying == nil
				? self.audioRecorder.play(recordings: Array(story.allRecordings))
				: self.audioRecorder.stopPlaying()
				
				if let index = self.collectionData.firstIndex(where: { $0.location.cid == story.id.stringValue }) {
					self.collectionData[index].cell.isPlaying = self.currentlyPlaying == story
				}
			}
		}
		
		return MapCollectionData(
			cell: MapStoryThumbnailCell.Content(
				image: story.mainImage,
				isPlaying: currentlyPlaying == story,
				playAction: action
			),
			location: IndexLocation(
				cid: story.id.stringValue,
				title: story.title,
				location: story.mainLocation
			)
		)
	}
	
	private func sortStoriesByLocation(stories: [Story]) -> [Story] {
		guard let location = location else {
			return stories
		}
		
		let result = stories.sorted(by: { story1, story2 in
			story1.mainLocation.distance(from: location) < story2.mainLocation.distance(from: location)
		})
		
		logger.info("MapVM sortStories: \(result.map{ $0.id })")
		return result
	}
	
	private func updateStories(with data: [Story]) {
		filterStories(with: activeFilters)
		saveTags()
		makeFilterContent()
	}
	
	private func addTestStory() {
		guard let imageData = StyleKit.image.make(from: StyleKit.image.examples.random())?.jpegData(compressionQuality: 0.0) else {
			return
		}
		
		let item1 = StoryPoint(
			image: imageData,
			location: location!.randomize()
		)
		
		let item2 = StoryPoint(
			image: imageData,
			location: location!.randomize()
		)
		
		item1.tags.append(objectsIn: [Tag.food.rawValue, Tag.museum.rawValue, Tag.hikes.rawValue, Tag.nature.rawValue])
		
		let story = Story(
			title: "Story \(storyDataProvider.stories.count)",
			collection: [item1, item2]
		)
		
		storyDataProvider.save(story: story)
	}
	
	// MARK: - Filtering
	
	private func saveTags() {
		var tags: [Tag] = []
		
		stories.forEach { story in
			story.allTags.forEach { tag in
				tags.append(tag)
			}
		}
		
		// Sort the tags by most occurencies
		let occurences = tags.reduce(into: [Tag: Int](), { result, element in
			result[element, default: 0] += 1
		})
		tags = tags.sorted(by: { occurences[$0] ?? 0 > occurences[$1] ?? 0 })
		
		allTags = tags.uniqueElements()
	}
	
	private func makeFilterContent() {
		filterContent = allTags.map { tag in
			TagButton.Content(
				title: tag.localizedTitle,
				isSelected: activeFilters.contains(tag),
				action: { [weak self] in
					guard let self = self else {
						return
					}
					
					if self.activeFilters.contains(tag) {
						self.activeFilters.removeAll { $0 == tag }
					} else {
						self.activeFilters.append(tag)
					}
					
					self.makeFilterContent()
				}
			)
		}
	}
	
	private func filterStories(with tags: [Tag]) {
		let sortedStories = sortStoriesByLocation(stories: storyDataProvider.stories)
		
		guard !tags.isEmpty else {
			stories = sortedStories
			return
		}
		
		stories = sortedStories.filter { story in
			let filters = Set(tags)
			return filters.isSubset(of: Set(story.allTags))
		}
	}
}

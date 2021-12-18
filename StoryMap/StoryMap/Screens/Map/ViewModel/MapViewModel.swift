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
	
	let addStorySubject = PassthroughSubject<Location, Never>()
	let openStorySubject = PassthroughSubject<Story, Never>()
	let openStoryListSubject = PassthroughSubject<Void, Never>()
	
	var storyInsertedSubject = PassthroughSubject<Story?, Never>()
	
	@Published private var stories: [Story] = []
	
	private let audioRecorder = AudioRecorder()
	private var subscribers = Set<AnyCancellable>()
	
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
	
	func addStory(with location: Location) {
		Configuration.isSimulator ? addTestStory() : addStorySubject.send(location)
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
		stories = sortStoriesByLocation(stories: data)
	}
	
	private func addTestStory() {
		guard let imageData = StyleKit.image.make(from: StyleKit.image.examples.random())?.jpegData(compressionQuality: 0.0) else {
			return
		}
		
		let item = StoryPoint(
			image: imageData,
			location: location!.randomize()
		)
		
		let story = Story(
			title: "Story \(storyDataProvider.stories.count)",
			collection: [item]
		)
		
		storyDataProvider.save(story: story)
	}
}

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
	
    private let audioRecorder = AudioRecorder.shared
	private var subscribers = Set<AnyCancellable>()
	
	private var currentlyPlaying: Story? {
		didSet {
            logger.info("MapVM: currentlyPlaying didSet")
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
		openStorySubject.send(stories[index])
	}
	
	func addStory(with location: Location) {
		Configuration.isSimulator ? addTestStory() : addStorySubject.send(location)
	}
	
	func openStoryList() {
		openStoryListSubject.send()
	}
	
	private func setupSubscribers() {
		$stories
			.sink { [weak self] stories in
				self?.collectionData = self?.makeCollectionData(from: stories) ?? []
			}
			.store(in: &subscribers)
		
		audioRecorder.$state
			.sink { [weak self] update in
                logger.info("MapVM: audioRecorder state update: \(String(describing: update))")
                if let playing = self?.audioRecorder.playQueue.first {
                    self?.currentlyPlaying = playing.story.first
                } else {
                    self?.currentlyPlaying = nil
                }
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
		return stories.enumerated().map { (index, story) in
            makeCollectionData(for: story, at: index)
		}
        
	}
	
    private func makeCollectionData(for story: Story, at index: Int) -> MapCollectionData {
		var action: (() -> Void)?

		if !story.audioRecordings.isEmpty {
			action = { [weak self] in
				guard let self = self else { return }
                if self.currentlyPlaying?.id.stringValue != self.collectionData[index].location.cid {
                    self.audioRecorder.play(recordings: Array(story.audioRecordings))
                    self.collectionData[index].cell.isPlaying = true
                    self.currentlyPlaying = story
                }
                else {
                    self.audioRecorder.stopPlaying()
                    self.collectionData[index].cell.isPlaying = false
                    self.currentlyPlaying = nil
                }
			}
		}
		
		return MapCollectionData(
			cell: MapStoryThumbnailCell.Content(
				image: story.uiImage,
				isPlaying: currentlyPlaying == story,
				playAction: action
			),
			location: IndexLocation(
				cid: story.id.stringValue,
                title: story.title,
				location: story.loc
			)
		)
	}
	
	private func sortStoriesByLocation(stories: [Story]) -> [Story] {
		guard let location = location else {
			return stories
		}
		
		let result = stories.sorted(by: { story1, story2 in
			story1.loc.distance(from: location) < story2.loc.distance(from: location)
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
		let n = collectionData.count
		let story = Story(
			title: "Story \(n)",
			image: imageData,
			location: location!.randomize()
		)
		
		storyDataProvider.save(story: story)
	}
}

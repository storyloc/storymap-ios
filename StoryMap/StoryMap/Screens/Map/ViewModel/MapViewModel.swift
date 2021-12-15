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

    var stories: [Story] {
        get {
            storyDataProvider.stories
        }
    }
	
	private let audioRecorder = AudioRecorder.shared
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
			
			updateStories()
			
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
	
    func updateStories() {
        guard let location = location else {
            storyDataProvider.sortStories(by: .none)
            return
        }

        storyDataProvider.sortStories(by: .distance(location: location))
    }

	private func setupSubscribers() {
        storyDataProvider.storyUpdateSubject
			.sink { [weak self] _ in
                self?.updateStories()
                self?.makeCollectionData()
			}
			.store(in: &subscribers)
		
		audioRecorder.$currentlyPlaying
			.sink { [weak self] rec in
                self?.currentlyPlaying = rec?.story.first
			}
			.store(in: &subscribers)
	}
	
	private func makeCollectionData() {
        collectionData = stories.map { story in
			makeCollectionData(for: story)
		}
	}
	
	private func makeCollectionData(for story: Story) -> MapCollectionData {
		var action: (() -> Void)?
		if !story.audioRecordings.isEmpty {
			action = { [weak self] in
				guard let self = self else { return }
				
				self.audioRecorder.currentlyPlaying == nil
				? self.audioRecorder.play(recordings: Array(story.audioRecordings))
				: self.audioRecorder.stopPlaying()
				
				if let index = self.collectionData.firstIndex(where: { $0.location.cid == story.id.stringValue }) {
					self.collectionData[index].cell.isPlaying = self.currentlyPlaying == story
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

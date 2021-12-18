//
//  StoryDataProvider.swift
//  StoryMap
//
//  Created by Dory on 02/12/2021.
//

import Combine
import RealmSwift
import UIKit

final class StoryDataProvider {
	enum Update {
		case initial(stories: [Story])
		case inserted(stories: [Story], insertedStory: Story)
	}
	
	// MARK: - Public properties
	
	static var shared = StoryDataProvider()
	
	@Published var stories: [Story] = []
	
	var storyUpdateSubject = PassthroughSubject<Update, Never>()
	
	// MARK: - Private properties
	
	private var results: Results<Story>?
	private let realm = RealmDataProvider.shared
	private var notificationToken: NotificationToken?
	
	// MARK: - Initializer
	
	private init() {
		subscribeToChanges()
	}
	
	// MARK: - Public methods
	
	func save(story: Story) {
		realm?.write(object: story)
	}
	
	func createStory(from image: UIImage, and location: Location) {
		guard let data = image.jpegData(compressionQuality: 0.0) else {
			logger.warning("StoryDP: createStory failed, couldn't convert image to data")
			return
		}
		
		let item = StoryPoint(
			image: data,
			location: Configuration.isSimulator
				? location.randomize()
				: Location(
					latitude: location.latitude,
					longitude: location.longitude
			)
		)
		
		let story = Story(
			title: "Story \(stories.count)",
			collection: [item]
		)
		realm?.write(object: story)
	}
	
	func delete(story: Story) {
		story.collection.forEach { point in
			realm?.deleteCascading(
				object: point,
				associatedObjects: [Array(point.audioRecordings)]
			)
		}
		
		realm?.deleteCascading(object: story, associatedObjects: [Array(story.collection)])
	}
	
	// MARK: - Recordings
	
	func add(recording: AudioRecording, to storyPoint: StoryPoint) {
		realm?.update(with: {
			storyPoint.audioRecordings.append(recording)
		})
	}
	
	func delete(recording: AudioRecording, from storyPoint: StoryPoint) {
		guard let index = storyPoint.audioRecordings.firstIndex(of: recording) else {
			return
		}
		
		realm?.update(with: {
			storyPoint.audioRecordings.remove(at: index)
		})
	}
	
	// MARK: - Tags
	
	func add(tags: [Tag], to storyPoint: StoryPoint) {
		realm?.update(with: {
			storyPoint.tags.removeAll()
			storyPoint.tags.append(objectsIn: tags.map { $0.rawValue })
		})
	}
	
	// MARK: - Private methods
	
	private func subscribeToChanges() {
		results = realm?.read(type: Story.self)
		
		notificationToken = results?.observe(on: .main, { [weak self] changes in
			switch changes {
			case .update(let items, _, let insertions, _):
				guard let self = self else { return }
				logger.info("StoryDP: realm results observer updated")
				
				self.stories = items.toArray(ofType: Story.self)
				
				guard let i = insertions.first else {
					self.storyUpdateSubject.send(.initial(stories: self.stories))
					return
				}
				
				self.storyUpdateSubject.send(.inserted(stories: self.stories, insertedStory: self.stories[i]))
			case .initial(let items):
				self?.stories = items.toArray(ofType: Story.self)
				self?.storyUpdateSubject.send(.initial(stories: self?.stories ?? []))
				logger.info("StoryDP: realm results observer initial")
			default: break
			}
		})
	}
}

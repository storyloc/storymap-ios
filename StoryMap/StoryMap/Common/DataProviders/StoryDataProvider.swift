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
	
	// MARK: - Public properties
	
	static var shared = StoryDataProvider()
	
	@Published var stories: [Story] = []
	
	// MARK: - Private properties
	
	private var results: Results<Story>?
	private let realm = RealmDataProvider.shared
	private var notificationToken: NotificationToken? = nil
	
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
		let story = Story(
			title: "Story \(stories.count)",
			image: data,
			location: Configuration.isSimulator
				? location.randomize()
				: location
		)
		realm?.write(object: story)
	}
	
	func delete(story: Story) {
		realm?.deleteCascading(
			object: story,
			associatedObjects: [Array(story.audioRecordings)]
		)
	}
	
	func add(recording: AudioRecording, to story: Story) {
		realm?.update(with: {
			story.audioRecordings.append(recording)
		})
	}
	
	func delete(recording: AudioRecording, from story: Story) {
		guard let index = story.audioRecordings.firstIndex(of: recording) else {
			return
		}
		
		realm?.update(with: {
			story.audioRecordings.remove(at: index)
		})
	}
	
	// MARK: - Private methods
	
	private func subscribeToChanges() {
		results = realm?.read(type: Story.self)
		
		notificationToken = results?.observe(on: .main, { [weak self] changes in
			switch changes {
			case .update(let items, _, _, _):
				self?.stories = items.toArray(ofType: Story.self)
				logger.info("StoryDP: realm results observer updated")
			case .initial(let items):
				self?.stories = items.toArray(ofType: Story.self)
				logger.info("StoryDP: realm results observer initial")
			default: break
			}
		})
	}
}

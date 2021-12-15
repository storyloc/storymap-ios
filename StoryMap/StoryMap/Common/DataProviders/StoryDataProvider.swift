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
		case initial
        case inserted
	}

    enum Sorting {
        case distance(location: Location)
        case none
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
        load(filter: "All")
	}
	
	// MARK: - Public methods

    func load(filter: String) {
        logger.info("StoryDataProvider: Loading, filter \(filter)")
        results = realm?.read(type: Story.self)
        subscribeToChanges()
        sortStories(by: .none)
    }

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
				: Location(
					latitude: location.latitude,
					longitude: location.longitude
				)
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
        logger.info("Story Recording delete: \(recording.id.stringValue) story: \(recording.story.first?.id.stringValue ?? "none")")
        realm?.delete(object: recording)
	}

    func sortStories(by sorting: Sorting) {
        logger.info("StoryDataProvider: sortStories")
        switch sorting {
        case .distance(let location):
            sortStoriesByDistance(from: location)
        default:
            stories = results?.toArray(ofType: Story.self) ?? []
        }
    }

    // MARK: - Private methods

    private func sortStoriesByDistance(from location: Location) {
        let resultArray = results?.toArray(ofType: Story.self) ?? []
        stories = resultArray.sorted(by: { story1, story2 in
            story1.loc.distance(from: location) < story2.loc.distance(from: location)
        })
    }

	private func subscribeToChanges() {
		notificationToken = results?.observe(on: .main, { [weak self] changes in

			switch changes {
			case .update(_, _, let insertions, _):
				guard let self = self else { return }
				logger.info("StoryDP: realm results observer updated")

                guard let i = insertions.first else {
					self.storyUpdateSubject.send(.initial)
					return
				}

                self.storyUpdateSubject.send(.inserted)

			case .initial(_):
                logger.info("StoryDP: realm results observer initial")
                self?.storyUpdateSubject.send(.initial)

			default: break
			}
		})
	}
}

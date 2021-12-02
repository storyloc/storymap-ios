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
    
    var onAddStory: ((Location) -> Void)?
    var onOpenStory: ((Story) -> Void)?
    var onOpenStoryList: (() -> Void)?
	
	@Published private var stories: [Story] = []
	
	private let audioRecorder = AudioRecorder()
	
	private var storiesObserver: AnyCancellable?
	private var currentlyPlayingObserver: AnyCancellable?
	private var recorderStateObserver: AnyCancellable?
	
	private var currentlyPlaying: Story? {
		didSet {
			for (i, cell) in collectionData.enumerated() {
				collectionData[i].cell.isPlaying = currentlyPlaying?.id.stringValue == cell.location.cid
			}
		}
	}
	
	lazy var storyDeleted: (Story) -> Void = { [weak self] story in
		guard let index = self?.stories.firstIndex(where: { $0 == story }) else {
			return
		}
		
		self?.stories.remove(at: index)
	}
	
    var location: Location? {
        didSet {
            guard oldValue == nil else {
                return
            }
            
            stories = sortStoriesByLocation(stories: stories)
            
            logger.info("MapVM:location didSet, start sorting")
        }
    }
    
    private var results: Results<Story>?
    private var notificationToken: NotificationToken? = nil
    
    private let realmDataProvider = RealmDataProvider.shared
    
    init() {
		setupObservers()
    }
    
    func openStory(with index: Int) {
		audioRecorder.stopPlaying()
        onOpenStory?(stories[index])
    }
    
    func addStory(with location: Location) {
		Configuration.isSimulator ? addTestStory() : onAddStory?(location)
		audioRecorder.stopPlaying()
    }

    func openStoryList() {
		audioRecorder.stopPlaying()
        onOpenStoryList?()
    }
	
	private func setupObservers() {
		setupRealmObserver()
		
		storiesObserver = $stories
			.sink { [weak self] stories in
				self?.collectionData = self?.makeCollectionData(from: stories) ?? []
			}
		
		currentlyPlayingObserver = audioRecorder.$currentlyPlaying
			.sink { [weak self] rec in
				guard let rec = rec else {
					self?.currentlyPlaying = nil
					return
				}
				
				let filteredStories = self?.stories.filter { story in
					story.audioRecordings.contains { recording in
						recording.id.stringValue == rec.id.stringValue
					}
				}
				
				self?.currentlyPlaying = filteredStories?.first
			}
	}
	
	private func setupRealmObserver() {
		results = realmDataProvider?.read(type: Story.self, with: nil)
		
		notificationToken = results?.observe(on: .main, { [weak self] changes in
			switch changes {
			case .update(let items, _, _, _):
				self?.updateStories(with: items)
				logger.info("MapVM: realm results observer updated")
			case .initial(let items):
				self?.updateStories(with: items)
				logger.info("MapVM: realm results observer initial")
			default: break
			}
		})
	}
	
    private func updateStories(with results: Results<Story>) {
        let data = results.toArray(ofType: Story.self)
        self.stories = self.sortStoriesByLocation(stories: data)
        
        logger.info("MapVM: collectionData updated")
    }
	
	private func makeCollectionData(from stories: [Story]) -> [MapCollectionData] {
		return stories.map { story in
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
    
    private func addTestStory() {
        guard let imageData = StyleKit.image.make(from: StyleKit.image.examples.random())?.jpegData(compressionQuality: 1) else {
            return
        }
        let n = collectionData.count
        let story = Story(
            title: "Story \(n)",
            image: imageData,
            location: location!.randomize()
        )
        realmDataProvider?.write(object: story)
    }
}

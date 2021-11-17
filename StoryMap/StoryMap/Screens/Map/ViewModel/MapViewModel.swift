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

protocol MapViewModelType: AnyObject {
    var collectionData: [Story] { get }
    var location: Location? { get set }
    
    func openStory(with index: Int)
    func addStory(with location: Location)
}

class MapViewModel: ObservableObject, MapViewModelType {
    @Published var collectionData: [Story] = []
    
    var onAddStory: ((Location) -> Void)?
    var onOpenStory: ((Story) -> Void)?
    
    var location: Location? {
        didSet {
            collectionData = sortStoriesByLocation(stories: collectionData)
            
            logger.info("MapVM:location didSet, start sorting")
        }
    }
    
    private var results: Results<Story>?
    private var notificationToken: NotificationToken? = nil
    
    private let realmDataProvider = RealmDataProvider.shared
    
    init() {
        loadStories()
        
        notificationToken = results?.observe(on: .main, { [weak self] changes in
            switch changes {
            case .update(let items, _, _, _):
                self?.collectionData = items.toArray(ofType: Story.self)
            default: break
            }
        })
    }
    
    func openStory(with index: Int) {
        onOpenStory?(collectionData[index])
    }
    
    func addStory(with location: Location) {
        #if targetEnvironment(simulator)
        addTestStory()
        #else
        onAddStory?(location)
        #endif
    }
    
    private func loadStories() {
        results = realmDataProvider?.read(type: Story.self, with: nil)

        if let results = results {
            let data = results.toArray(ofType: Story.self)
            collectionData = sortStoriesByLocation(stories: data)
        }
        
        logger.info("MapVM: loaded stories from realm")
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
        loadStories()
    }
}

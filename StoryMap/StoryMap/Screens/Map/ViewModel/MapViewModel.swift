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
            sortStoriesByLocation()
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
            collectionData = results.toArray(ofType: Story.self)
        }
        sortStoriesByLocation()
    }
    
    private func sortStoriesByLocation() {
        guard let location = location else {
            return
        }

        collectionData = collectionData.sorted(by: { story1, story2 in
            story1.loc.distance(from: location) < story2.loc.distance(from: location)
        })
        
        collectionData.forEach {
            print($0.id.stringValue)
            print($0.loc.distance(from: location))
        }
    }
    
    private func addTestStory() {
        guard let imageData = StyleKit.image.make(from: StyleKit.image.examples.waterfall)?.jpegData(compressionQuality: 1) else {
            return
        }
        let story = Story(
            title: "Title",
            image: imageData,
            location: location!.randomize()
        )
        realmDataProvider?.write(object: story)
        loadStories()
    }
}

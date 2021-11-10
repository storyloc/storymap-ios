//
//  MapViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import RealmSwift

protocol MapViewModelType: AnyObject {
    var collectionData: [Story] { get }
    var onUpdate: (() -> Void)? { get set }
    
    func openStory(with index: Int)
    func addStory(with location: Location)
}

class MapViewModel: MapViewModelType {
    var collectionData: [Story] = []
    var onUpdate: (() -> Void)?
    
    var onAddStory: ((Location) -> Void)?
    var onOpenStory: ((Story) -> Void)?
    
    private var results: Results<Story>?
    private var notificationToken: NotificationToken? = nil
    
    private let realmDataProvider = RealmDataProvider.shared
    
    init() {
        results = realmDataProvider?.read(type: Story.self, with: nil)
        if let results = results {
            collectionData = results.toArray(ofType: Story.self)
        }
        
        notificationToken = results?.observe(on: .main, { [weak self] changes in
            switch changes {
            case .update(let items, _, _, _):
                self?.collectionData = items.toArray(ofType: Story.self)
                self?.onUpdate?()
            default: break
            }
        })
    }
    
    func openStory(with index: Int) {
        onOpenStory?(collectionData[index])
    }
    
    func addStory(with location: Location) {
        onAddStory?(location)
    }
}

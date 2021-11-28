//
//  DebugViewModel.swift
//  StoryMap
//
//  Created by Felix Böhm on 28.11.21.
//

import Foundation
import RealmSwift
import SwiftUI
import Combine

final class StoryListViewModel {

    var onClose: (() -> Void)?
    var onAddStory: ((Location) -> Void)?
    var onOpenStory: ((Story) -> Void)?
    
    // MARK: - Public properties
    
    @Published var stories: [Story] = []
    
    var location: Location? {
        didSet {
            guard oldValue == nil else {
                return
            }
            logger.info("StoryListVM: location didSet")
        }
    }

    // MARK: - Private properties
    
    private let realmDataProvider = RealmDataProvider.shared
    private var results: Results<Story>?
    private var notificationToken: NotificationToken? = nil

    init() {
        setupObservers()
    }

    func openStory(with index: Int) {
        logger.info("StoryListVM: open Story \(index)")
        onOpenStory?(stories[index])
    }

    func addStory(with location: Location) {
        logger.info("StoryListVM: addStory")
        onAddStory?(location)
    }

    // MARK: - Private methods
    
    private func setupObservers() {
        self.setupRealmObserver()
    }

    private func setupRealmObserver() {
        results = realmDataProvider?.read(type: Story.self, with: nil)
        
        notificationToken = results?.observe(on: .main, { [weak self] changes in
            switch changes {
            case .update(let items, _, _, _):
                self?.updateStories(with: items)
                logger.info("StoryListVM: realm results observer updated")
            case .initial(let items):
                self?.updateStories(with: items)
                logger.info("StoryListVM: realm results observer initial")
            default: break
            }
        })
    }
    
    private func updateStories(with results: Results<Story>) {
        self.stories = results.toArray(ofType: Story.self)
    }
}

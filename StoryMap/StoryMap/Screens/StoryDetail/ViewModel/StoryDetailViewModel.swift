//
//  StoryDetailViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import Combine

protocol StoryDetailViewModelType: AnyObject {
    var story: Story { get }
    var state: StoryDetailViewModel.RecordingState { get }
    func delete()
    func startRecording()
    func stopRecording()
}

class StoryDetailViewModel: ObservableObject, StoryDetailViewModelType {
    enum RecordingState: String {
        case initial
        case inProgress
        case done
    }
    
    var story: Story
    
    @Published var state: RecordingState = .initial
    
    var onClose: (() -> Void)?
    
    private let realmDataProvider = RealmDataProvider.shared
    
    init(story: Story) {
        self.story = story
    }
    
    func delete() {
        logger.info("DetailVM: deleteStory: \(self.story)")
        realmDataProvider?.delete(object: story)
        onClose?()
    }
    
    func startRecording() {
        logger.info("DetailVM: startRecording")
        guard state != .inProgress else {
            logger.warning("DetailVM: invalid state: \(self.state.rawValue)")
            return
        }
        
        state = .inProgress
    }
    
    func stopRecording() {
        logger.info("DetailVM: stopRecording")
        guard state == .inProgress else {
            logger.warning("DetailVM: invalid state: \(self.state.rawValue)")
            return
        }
        
        state = .done
    }
}

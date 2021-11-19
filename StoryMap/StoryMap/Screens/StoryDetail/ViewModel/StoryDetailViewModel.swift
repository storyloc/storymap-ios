//
//  StoryDetailViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import Combine
import SwiftUI

typealias AudioRecordingInfo = (recording: AudioRecording, isPlaying: Bool)

protocol StoryDetailViewModelType: AnyObject {
    var story: Story { get }
    var state: StoryDetailViewModel.RecordingState { get }
    var recordings: [AudioRecordingInfo] { get }
    
    func play(recording: AudioRecording)
    func delete()
    func startRecording()
    func stopRecording()
}

final class StoryDetailViewModel: ObservableObject, StoryDetailViewModelType {
    enum RecordingState: String {
        case initial
        case inProgress
        case done
    }
    
    // MARK: - Public properties
    
    var story: Story
    
    @Published var state: RecordingState = .initial
    @Published var recordButtonEnabled = false
    @Published var recordings: [AudioRecordingInfo]
    
    var onClose: (() -> Void)?
    
    // MARK: - Private properties
    
    private let realmDataProvider = RealmDataProvider.shared
    
    @ObservedObject private var audioRecorder = AudioRecorder()
    
    // MARK: - Observers
    
    private var recorderStateObserver: AnyCancellable?
    private var recordingAllowedObserver: AnyCancellable?
    private var currentlyPlayingObserver: AnyCancellable?
    
    init(story: Story) {
        self.story = story
        self.recordings = story.audioRecordings.map { AudioRecordingInfo(recording: $0, isPlaying: false) }
        
        setupObservers()
    }
    
    // MARK: - Public methods
    
    func delete() {
        logger.info("DetailVM: deleteStory: \(self.story)")
        
        realmDataProvider?.delete(object: story)
        onClose?()
    }
    
    func startRecording() {
        logger.info("DetailVM: startRecording")

        audioRecorder.startRecording()
        print("ALLOWED: \(audioRecorder.recordingAllowed)")
    }
     
    func stopRecording() {
        logger.info("DetailVM: stopRecording")
        
        audioRecorder.stopRecording()
    }
    
    func play(recording: AudioRecording) {
        audioRecorder.play(recording: recording)
    }
    
    // MARK: - Private methods
    
    private func setupObservers() {
        recordingAllowedObserver = audioRecorder.$recordingAllowed.assign(to: \.recordButtonEnabled, on: self)
        
        recorderStateObserver = audioRecorder.$state.sink { [weak self] recState in
            logger.info("DetailVM: recorderStateObserver: \(String(describing: recState))")
            switch recState {
                
            case .initial:
                self?.state = .initial
            case .recording:
                self?.state = .inProgress
            case .recorded(let recording):
                self?.saveRecording(recording)
                self?.state = .done
            case .playing:
                break
            case .error(message: let message):
                break
            }
        }
        
        currentlyPlayingObserver = audioRecorder.$currentlyPlaying.sink { [weak self] recording in
            guard let self = self else { return }
            
            logger.info("DetailVM: currentlyPlayingObserver: \(recording?.createdAt ?? "nil")")
            
            self.recordings = self.recordings.map { rec in
                AudioRecordingInfo(recording: rec.recording, isPlaying: rec.recording == recording)
            }
        }
    }
    
    private func saveRecording(_ recording: AudioRecording) {
        recordings.append(AudioRecordingInfo(recording: recording, isPlaying: false))
        
        realmDataProvider?.update(with: { [weak self] in
            self?.story.audioRecordings.append(recording)
        })
    }
    
}

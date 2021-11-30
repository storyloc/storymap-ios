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

final class StoryDetailViewModel {
    enum RecordingState: String {
        case initial
        case inProgress
        case done
		case permissionDenied
    }
	
	enum RecordingsUpdate {
		case delete(Int)
		case update([AudioRecordingInfo])
	}
    
    // MARK: - Public properties
    
    var story: Story
    
    @Published var state: RecordingState = .initial
    @Published var recordButtonEnabled = false
	
	let recordingsSubject = PassthroughSubject<RecordingsUpdate, Never>()
	
	var onDeleteStory: ((Story) -> Void)?
    var onClose: (() -> Void)?
    
    // MARK: - Private properties
    
    private let realmDataProvider = RealmDataProvider.shared
    
    @ObservedObject private var audioRecorder = AudioRecorder()
	
	private var recordings: [AudioRecordingInfo]
    
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
    
	func load() {
		recordingsSubject.send(.update(recordings))
	}
	
    func delete() {
        logger.info("DetailVM: deleteStory: \(self.story)")
        
		self.realmDataProvider?.deleteCascading(object: story, associatedObjects: [Array(story.audioRecordings)])
		onDeleteStory?(story)
    }
	
	func deleteRecording(at index: Int) {
		logger.info("DetailVM: deleteRecording at \(index)")
		
		recordings.remove(at: index)
		recordingsSubject.send(.delete(index))
		
		realmDataProvider?.update(with: { [weak self] in
			self?.story.audioRecordings.remove(at: index)
		})
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
	
	func playAll() {
		guard !recordings.isEmpty else {
			logger.info("DetailVM: playAllRecordings failed: recordings are empty")
			return
		}
		audioRecorder.play(recordings: recordings.map { $0.recording })
		logger.info("DetailVM: playAllRecordings")
	}
	
	func stopPlaying() {
		audioRecorder.stopPlaying()
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
            case .error(let error):
				if case .permissionDenied = error {
					self?.state = .permissionDenied
				}
            }
        }
        
        currentlyPlayingObserver = audioRecorder.$currentlyPlaying.sink { [weak self] recording in
            guard let self = self else { return }
            
            logger.info("DetailVM: currentlyPlayingObserver: \(recording?.createdAt ?? "nil")")
            
            self.recordings = self.recordings.map { rec in
                AudioRecordingInfo(recording: rec.recording, isPlaying: rec.recording == recording)
            }
			self.recordingsSubject.send(.update(self.recordings))
        }
    }
    
    private func saveRecording(_ recording: AudioRecording) {
        recordings.append(AudioRecordingInfo(recording: recording, isPlaying: false))
		recordingsSubject.send(.update(recordings))
        
        realmDataProvider?.update(with: { [weak self] in
            self?.story.audioRecordings.append(recording)
        })
    }
}

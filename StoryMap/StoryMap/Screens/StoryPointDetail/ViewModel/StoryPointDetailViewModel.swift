//
//  StoryPointDetailViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import Combine
import SwiftUI

typealias AudioRecordingInfo = (recording: AudioRecording, isPlaying: Bool)

final class StoryPointDetailViewModel {
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
	
	var storyPoint: StoryPoint
	
	@Published var state: RecordingState = .initial
	@Published var tagContent: [TagButton.Content] = []
	
	let recordingsSubject = PassthroughSubject<RecordingsUpdate, Never>()
	let closeSubject = PassthroughSubject<Void, Never>()
	
	// MARK: - Private properties
	
	private let storyDataProvider = StoryDataProvider.shared
	
	@ObservedObject private var audioRecorder = AudioRecorder()
	
	private var recordings: [AudioRecordingInfo]
	
	private lazy var selectedTags: [Tag] = storyPoint.tagArray {
		didSet {
			makeTagContent()
		}
	}
	
	private var subscribers = Set<AnyCancellable>()
	
	init(storyPoint: StoryPoint) {
		self.storyPoint = storyPoint
		self.recordings = Array(storyPoint.audioRecordings).compactMap { rec in
			AudioRecordingInfo(recording: rec, isPlaying: false)
		}
		
		setupSubscribers()
		makeTagContent()
	}
	
	deinit {
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
	}
	
	// MARK: - Public methods
	
	func load() {
		recordingsSubject.send(.update(recordings))
	}
	
	func delete() {
		logger.info("DetailVM: deleteStoryPoint: \(self.storyPoint)")
		
		guard let story = storyPoint.story.first else {
			return 
		}
		
		storyDataProvider.delete(storyPoint: storyPoint, from: story)
	}
	
	func deleteRecording(at index: Int) {
		logger.info("DetailVM: deleteRecording at \(index)")
		
		recordings.remove(at: index)
		recordingsSubject.send(.delete(index))
		
		storyDataProvider.delete(
			recording: storyPoint.audioRecordings[index],
			from: storyPoint
		)
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
	
	func saveTags() {
		guard storyPoint.tagArray != selectedTags else {
			return
		}
		
		storyDataProvider.add(tags: selectedTags, to: storyPoint)
	}
	
	// MARK: - Private methods
	
	private func setupSubscribers() {
		audioRecorder.$state
			.sink { [weak self] recState in
				logger.info("DetailVM: recorderStateObserver: \(String(describing: recState))")
				self?.updateState(with: recState)
			}
			.store(in: &subscribers)
		
		audioRecorder.$currentlyPlaying
			.sink { [weak self] recording in
				logger.info("DetailVM: currentlyPlayingObserver: \(recording?.createdAt ?? "nil")")
				
				self?.updateRecordings(with: recording)
			}
			.store(in: &subscribers)
	}
	
	private func updateState(with recState: AudioRecorder.State) {
		switch recState {
			
		case .initial:
			state = .initial
		case .recording:
			state = .inProgress
		case .recorded(let recording):
			saveRecording(recording)
			state = .done
		case .playing:
			break
		case .error(let error):
			if case .permissionDenied = error {
				state = .permissionDenied
			}
		}
	}
	
	private func updateRecordings(with currentlyPlaying: AudioRecording?) {
		recordings = recordings.map { rec in
			AudioRecordingInfo(recording: rec.recording, isPlaying: rec.recording == currentlyPlaying)
		}
		
		recordingsSubject.send(.update(recordings))
	}
	
	private func saveRecording(_ recording: AudioRecording) {
		recordings.append(AudioRecordingInfo(recording: recording, isPlaying: false))
		recordingsSubject.send(.update(recordings))
		
		storyDataProvider.add(recording: recording, to: storyPoint)
	}
	
	private func makeTagContent() {
		let allTags = Tag.allCases
		let content = allTags.map { tag in
			TagButton.Content(
				title: tag.localizedTitle,
				isSelected: selectedTags.contains(tag),
				action: { [weak self] in
					guard let self = self else {
						return
					}
					
					if self.selectedTags.contains(tag) {
						self.selectedTags.removeAll { $0 == tag }
					} else {
						self.selectedTags.append(tag)
					}
					
					self.makeTagContent()
				}
			)
		}
		tagContent = content.sorted { $0.isSelected && !$1.isSelected }
	}
}

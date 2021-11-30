//
//  AudioRecorder.swift
//  StoryMap
//
//  Created by Dory on 18/11/2021.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

final class AudioRecorder: NSObject, ObservableObject {
    enum State {
        case initial
        case recording
        case recorded(AudioRecording)
        case playing
		case error(AudioRecorder.Error)
    }
	
	enum Error: Swift.Error {
		case permissionDenied
		case unknown(Swift.Error?)
	}
    
    // MARK: - Public properties
    
    @Published var recordingAllowed = false
    @Published var state: State = .initial
    @Published var currentlyPlaying: AudioRecording? = nil
    
    // MARK: - Private properties
    
    private let recordingSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
	private var playQueue: [AudioRecording]?
    
    override init() {
        super.init()
        
        do {
            try recordingSession.setCategory(.playAndRecord,
                                             mode: .default,
                                             options: [
                                                .defaultToSpeaker,
                                                .allowBluetooth,
                                                .allowAirPlay,
                                                .mixWithOthers
                                             ]
            )
            try recordingSession.setActive(true)
        } catch {
			state = .error(.unknown(error))
            logger.error("AudioRecorder: setup failed: \(error.localizedDescription)")
        }
		
		askForMicrophonePermissions()
    }
    
    // MARK: - Public methods
    
    public func startRecording() {
        stopPlaying()
        
        guard recordingAllowed else {
            logger.warning("AudioRecorder: startRecording failed: missing permissions.")
            return
        }
        
        let audioFileURL = getDocumentsDirectory().appendingPathComponent("storymap-\(Date().timeIntervalSince1970).m4a")
        audioURL = audioFileURL
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            state = .recording
            logger.error("AudioRecorder: startRecording success")
        } catch {
            state = .error(.unknown(error))
            logger.error("AudioRecorder: startRecording failed: \(error.localizedDescription)")
        }
    }
    
    public func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    public func play(recording: AudioRecording) {
		do {
			audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent(recording.fileName))
			audioPlayer?.delegate = self
			audioPlayer?.play()
			
			currentlyPlaying = recording
			state = .playing
			logger.info("AudioRecorder: playRecording: \(recording.createdAt)")
		} catch {
			logger.warning("AudioRecorder: playRecording failed: \(error.localizedDescription)")
		}
    }
	
	public func play(recordings: [AudioRecording]) {
		playQueue = recordings
		
		if let first = recordings.first {
			play(recording: first)
		}
	}
    
    public func stopPlaying() {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
            currentlyPlaying = nil
			
            logger.info("AudioRecorder: stopPlaying")
			
			guard let playQueue = playQueue, !playQueue.isEmpty else {
				return
			}
			
			state = .initial
        } else {
            logger.warning("AudioRecorder: stopPlaying failed: audioPlayer is nil")
        }
    }
    
    public func askForMicrophonePermissions() {
		guard recordingSession.recordPermission == .undetermined else {
			self.recordingAllowed = recordingSession.recordPermission == .granted
			return
		}
		
        recordingSession.requestRecordPermission() { [weak self] allowed in
            DispatchQueue.main.async {
				self?.recordingAllowed = allowed
            }
        }
    }
                         
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
                         
// MARK: - AVAudioRecorderDelegate
                         
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            guard let audioURL = audioURL else {
                logger.warning("AudioRecorder: finishRecording failed - fileURL is missing")
                return
            }

            let player = try? AVAudioPlayer(contentsOf: audioURL)
            let recording = AudioRecording(
                fileName: audioURL.lastPathComponent,
                length: player?.duration ?? 0
            )
            state = .recorded(recording)
            logger.info("AudioRecorder: finishRecording success")
        } else {
			state = .error(.unknown(nil))
            logger.error("AudioRecorder: finishRecording failed.")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        logger.info("AudioRecorder: didFinishPlaying")
		
        stopPlaying()
		
		if let queue = playQueue, !queue.isEmpty {
			playQueue?.removeFirst()
			
			if let next = playQueue?.first {
				play(recording: next)
			}
		}
    }
}

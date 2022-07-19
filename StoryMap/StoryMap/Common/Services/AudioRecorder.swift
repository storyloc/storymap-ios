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

final class AudioRecorder: NSObject {
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
    
    static var shared = AudioRecorder()

    @Published var recordingAllowed = false
    @Published var state: State = .initial
    @Published var currentlyPlaying: AudioRecording? = nil

    var playQueue: [AudioRecording] = []
    
    // MARK: - Private properties
    
    private let recordingSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    
    private override init() {
        super.init()
        
        do {
            try recordingSession.setCategory(.playAndRecord,
                                             mode: .videoRecording,
                                             options: [
                                                .defaultToSpeaker,
                                                .allowBluetooth,
                                                .allowAirPlay
                                             ]
            )
        } catch {
			state = .error(.unknown(error))
            logger.error("AudioRecorder: setup failed: \(error.localizedDescription)")
        }
        askForMicrophonePermissions()
    }
    
    // MARK: - Public methods
    
    public func startRecording() {
        guard recordingAllowed else {
            logger.warning("AudioRecorder: startRecording failed: missing permissions.")
            return
        }
        if audioPlayer != nil {
            stopPlaying()
        }
        setPreferedRecordingInput()
        
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
            try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
            audioRecorder?.record()
            state = .recording
            logger.error("AudioRecorder: startRecording success")
        } catch {
            state = .error(.unknown(error))
            logger.error("AudioRecorder: startRecording failed: \(error.localizedDescription)")
        }
    }
    
    public func stopRecording() {
        do {
            audioRecorder?.stop()
            audioRecorder = nil
            try recordingSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error(.unknown(error))
            logger.error("AudioRecorder deactivate session failed: \(error.localizedDescription)")
        }
    }
    
    public func play() {
        guard let recording = playQueue.first, !playQueue.isEmpty else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent(recording.fileName))
            audioPlayer?.volume = 20.0 // higher value ducks background music more
            audioPlayer?.delegate = self
            try recordingSession.setCategory(.ambient, options: [.duckOthers, .mixWithOthers])
            try recordingSession.setActive(true)
            audioPlayer?.play()
            currentlyPlaying = recording
            state = .playing
            logger.info("AudioRecorder: playRecording: \(recording.createdAt)")
        } catch {
            logger.warning("AudioRecorder: playRecording failed: \(error.localizedDescription)")
        }
    }
    public func play(recording: AudioRecording) {
        stopPlaying()
        playQueue = [recording]
        play()
    }
	
	public func play(recordings: [AudioRecording]) {
        stopPlaying()
		playQueue = recordings
        play()
	}
    
    public func stopPlaying() {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
            do {
                try recordingSession.setActive(false)
                try recordingSession.setCategory(
                    .playAndRecord,
                    mode: .videoRecording,
                    options: [
                        .defaultToSpeaker,
                        .allowBluetooth,
                        .allowAirPlay
                     ]
                )
            }
            catch {
                logger.warning("AudioRecorder: stopPlaying failed: \(error.localizedDescription)")
            }
            logger.info("AudioRecorder: stopPlaying")
            playQueue = []
            currentlyPlaying = nil
			state = .initial
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

    private func setPreferedRecordingInput() {
        do {
            if let availableInputs = recordingSession.availableInputs {
                let input = availableInputs.count > 1
                    ? availableInputs[1]
                    : availableInputs[0]
                try recordingSession.setPreferredInput(input)
            }
        }
        catch {
            logger.warning("AudioRecorder: preferedInput failed: \(error.localizedDescription)")
        }
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
            logger.info("AudioRecorder: finishRecording success, length \(recording.length)s")
            state = .initial
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

        if !playQueue.isEmpty {
            playQueue.removeFirst()
        }
		if !playQueue.isEmpty {
            logger.info("AudioRecorder: play next in queue")
            state = .initial    // reset to update in play() for each new played recording
			play()
		} else {
            stopPlaying()
        }
    }
}

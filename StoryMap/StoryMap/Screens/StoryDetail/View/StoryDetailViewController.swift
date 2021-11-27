//
//  StoryDetailViewController.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import UIKit
import Combine
import SwiftUI

class StoryDetailViewController: UIViewController {
    
    // MARK: - Private properties
    
	private var viewModel: StoryDetailViewModel

    private let imageView = UIImageView()
    private let recordButton = UIButton(type: .custom)
    private let tableView = UITableView(frame: .zero, style: .plain)
	private let playAllButton = UIButton(type: .system)
	
    private var recordings: [AudioRecordingInfo] = []
    
    private let reuseIdentifier = "RecordingCell"
    
    // MARK: - Observers
	
    private var stateObserver: AnyCancellable?
    private var recordingsObserver: AnyCancellable?
    private var recordButtonEnabledObserver: AnyCancellable?
    
    // MARK: - Initializers
    
    init(viewModel: StoryDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        setupUI()
		setupObservers()
		viewModel.load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		recordButton.clipsToBounds = true
		recordButton.layer.cornerRadius = recordButton.frame.height / 2
	}
	
	// MARK: - Private methods
    
    private func setupUI() {
        title = viewModel.story.title
        view.backgroundColor = .white
        
        [imageView, tableView, recordButton, playAllButton].forEach(view.addSubview)
        
        setupNavBar()
        setupImageView()
        setupRecordButton()
        setupTableView()
		setupPlayAllButton()
        setupGestureRecognizer()
    }
    
    private func setupObservers() {
        stateObserver = viewModel.$state.sink { [weak self] state in
            self?.updateRecordButton(with: state)
            logger.info("DetailVC: stateObserver changed: \(state.rawValue)")
        }
        recordingsObserver = viewModel.recordingsSubject.sink { [weak self] info in
			logger.info("DetailVC: recordingsObserver changed")
			
			guard let self = self else { return }
			
			switch info {
			case .update(let recordings):
				self.recordings = recordings
				self.tableView.reloadData()
				
				logger.info("DetailVC: recordingsUpdated: \(recordings)")
			case .delete(let index):
				self.recordings.remove(at: index)
				self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
			}
			
			guard !self.recordings.isEmpty else {
				self.tableView.isHidden = true
				self.playAllButton.isHidden = true
				return
			}
			
			self.playAllButton.isHidden = false
			self.tableView.isHidden = false
        }
    }
    
    private func setupNavBar() {
        let rightButton = UIBarButtonItem(
            image: StyleKit.image.make(from: StyleKit.image.icons.delete, with: .alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(deleteTapped)
        )
        navigationItem.rightBarButtonItem = rightButton
    }
    
    private func setupRecordButton() {
        recordButton.setImage(
            StyleKit.image.make(from: StyleKit.image.icons.record, with: .alwaysTemplate),
            for: .normal
        )
        
        recordButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(StyleKit.metrics.padding.common)
            make.width.height.equalTo(StyleKit.metrics.recordButtonSize)
        }
		
		recordButton.layer.borderWidth = StyleKit.metrics.separator
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(recordButton.snp.bottom).offset(StyleKit.metrics.padding.common)
            make.leading.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(data: viewModel.story.image)
        
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.verySmall)
			make.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.4)
            make.centerX.equalToSuperview()
        }
    }
	
	private func setupPlayAllButton() {
		playAllButton.setTitle(LocalizationKit.storyDetail.playAllButtonTitle, for: .normal)
		playAllButton.tintColor = .systemBlue
		
		playAllButton.addTarget(self, action: #selector(playAllTapped), for: .touchUpInside)
		
		playAllButton.snp.makeConstraints { make in
			make.leading.equalTo(36)
			make.bottom.equalTo(tableView.snp.top).offset(-StyleKit.metrics.padding.small)
		}
	}
    
    private func setupGestureRecognizer() {
        let recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        recordButton.addGestureRecognizer(recognizer)
    }
    
    private func updateRecordButton(with state: StoryDetailViewModel.RecordingState) {
        switch state {
        case .initial, .done:
			recordButton.isEnabled = true
            recordButton.backgroundColor = .white
            recordButton.tintColor = .systemBlue
			recordButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .inProgress:
			recordButton.isEnabled = true
            recordButton.backgroundColor = .red
            recordButton.tintColor = .white
			recordButton.layer.borderColor = UIColor.red.cgColor
		case .permissionDenied:
			recordButton.isEnabled = false
			recordButton.backgroundColor = .white
			recordButton.tintColor = .systemBlue
			recordButton.layer.borderColor = UIColor.systemBlue.cgColor
		}
    }
    
	private func humanReadableTime(from length: Double) -> String? {
		let input: Double = length > 1 ? length : 1
		
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		formatter.unitsStyle = .abbreviated

		return formatter.string(from: TimeInterval(input))
	}
	
    // MARK: - Actions
    
    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began: viewModel.startRecording()
        case .cancelled, .ended: viewModel.stopRecording()
        default: break
        }
    }
    
    @objc private func deleteTapped() {
        viewModel.delete()
    }
	
	@objc private func playAllTapped() {
		viewModel.playAll()
	}
}

// MARK: - UITableViewDelegate

extension StoryDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = recordings[indexPath.row]
		recording.isPlaying
			? viewModel.stopPlaying()
			: viewModel.play(recording: recording.recording)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension StoryDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellData = recordings[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        var content = cell.defaultContentConfiguration()
		
		content.text = humanReadableTime(from: cellData.recording.length)
		content.secondaryText = cellData.recording.createdAt
		
        content.image = StyleKit.image.make(
            from: cellData.isPlaying ? StyleKit.image.icons.pause : StyleKit.image.icons.play,
            with: .alwaysTemplate
        )
		
        cell.contentConfiguration = content
        return cell
    }
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			viewModel.deleteRecording(at: indexPath.row)
		}
	}
}

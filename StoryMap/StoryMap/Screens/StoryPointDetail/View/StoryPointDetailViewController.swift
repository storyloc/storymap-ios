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

class StoryPointDetailViewController: UIViewController {
	
	// MARK: - Public properties
	
	var index: Int = 0
	
	// MARK: - Private properties
	
	private var viewModel: StoryPointDetailViewModel
	
	private let imageView = UIImageView()
	private let recordButton = UIButton(type: .custom)
	private var recordButtonShadow = UIView()
	private let tableView = UITableView(frame: .zero, style: .plain)
	private let tagView = TagFilterView()
	
	private var recordings: [AudioRecordingInfo] = []
	
	private let reuseIdentifier = "RecordingCell"
	
	// MARK: - Observers
	
	private var subscribers = Set<AnyCancellable>()
	
	// MARK: - Initializers
	
	init(viewModel: StoryPointDetailViewModel) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Overrides
	
	override func viewDidLoad() {
		setupUI()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupSubscribers()
		viewModel.load()
		navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		recordButton.clipsToBounds = true
		recordButton.layer.cornerRadius = recordButton.frame.height / 2
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		viewModel.saveTags()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
	}
	
	// MARK: - Private methods
	
	private func setupUI() {
		view.backgroundColor = .white
		
		[imageView, tableView, recordButton, tagView].forEach(view.addSubview)
		
		setupImageView()
		setupTagView()
		setupRecordButton()
		setupRecordButtonShadow()
		setupTableView()
		setupGestureRecognizer()
	}
	
	private func setupSubscribers() {
		viewModel.$state
			.receive(on: DispatchQueue.main)
			.sink { [weak self] state in
				self?.updateRecordButton(with: state)
				logger.info("DetailVC: stateObserver changed: \(state.rawValue)")
			}
			.store(in: &subscribers)
		
		viewModel.recordingsSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] update in
				logger.info("DetailVC: recordingsObserver changed")
				
				self?.updateRecordings(update)
			}
			.store(in: &subscribers)
		
		viewModel.$tagContent
			.receive(on: DispatchQueue.main)
			.sink { [weak self] content in
				self?.tagView.update(with: content)
			}
			.store(in: &subscribers)
	}
	
	private func updateRecordings(_ update: StoryPointDetailViewModel.RecordingsUpdate) {
		switch update {
		case .update(let data):
			recordings = data
			tableView.reloadData()
			
			logger.info("DetailVC: recordingsUpdated: \(data)")
		case .delete(let index):
			recordings.remove(at: index)
			tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
		}
		
		guard !recordings.isEmpty else {
			tableView.isHidden = true
			return
		}
		
		tableView.isHidden = false
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
	
	private func setupTagView() {
		tagView.contentInset = UIEdgeInsets(
			top: 0,
			left: StyleKit.metrics.padding.small,
			bottom: 0,
			right: StyleKit.metrics.padding.small
		)
		
		tagView.snp.makeConstraints { make in
			make.top.equalTo(recordButton.snp.bottom).offset(StyleKit.metrics.padding.common)
			make.leading.trailing.equalToSuperview()
			make.height.equalTo(StyleKit.metrics.padding.medium)
		}
	}
	
	private func setupRecordButtonShadow() {
		view.insertSubview(recordButtonShadow, belowSubview: recordButton)
		recordButtonShadow.clipsToBounds = true
		recordButtonShadow.layer.cornerRadius = StyleKit.metrics.recordButtonSize * 1.5 / 2
		recordButtonShadow.backgroundColor = .white
		
		recordButtonShadow.snp.makeConstraints { make in
			make.centerX.centerY.equalTo(recordButton)
			make.size.equalTo(recordButton).multipliedBy(1.5)
		}
	}
	
	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self
		tableView.estimatedRowHeight = UITableView.automaticDimension
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
		
		tableView.snp.makeConstraints { make in
			make.top.equalTo(tagView.snp.bottom).offset(StyleKit.metrics.padding.medium)
			make.leading.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
			make.bottom.equalToSuperview()
		}
	}
	
	private func setupImageView() {
		imageView.contentMode = .scaleAspectFit
		imageView.image = viewModel.storyPoint.uiImage
		
		view.addSubview(imageView)
		
		imageView.snp.makeConstraints { make in
			make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.verySmall)
			make.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.4)
			make.leading.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
		}
	}
	
	private func setupGestureRecognizer() {
		let recognizer = UILongPressGestureRecognizer(
			target: self,
			action: #selector(handleLongPress)
		)
		recognizer.minimumPressDuration = 0
		recognizer.allowableMovement = 150        // Large area
		recordButton.addGestureRecognizer(recognizer)
	}
	
	private func updateRecordButton(with state: StoryPointDetailViewModel.RecordingState) {
		switch state {
		case .initial, .done:
			recordButton.isEnabled = true
			recordButton.backgroundColor = .white
			recordButton.tintColor = .systemBlue
			recordButton.layer.borderColor = UIColor.systemBlue.cgColor
			recordButtonShadow.backgroundColor = .white
		case .inProgress:
			recordButton.isEnabled = true
			recordButton.backgroundColor = .red
			recordButton.tintColor = .white
			recordButton.layer.borderColor = UIColor.red.cgColor
			recordButtonShadow.backgroundColor = UIColor.red.withAlphaComponent(0.4)
		case .permissionDenied:
			recordButton.isEnabled = false
			recordButton.backgroundColor = .white
			recordButton.tintColor = .systemBlue
			recordButton.layer.borderColor = UIColor.systemBlue.cgColor
			recordButtonShadow.backgroundColor = .white
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

extension StoryPointDetailViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let recording = recordings[indexPath.row]
		recording.isPlaying
		? viewModel.stopPlaying()
		: viewModel.play(recording: recording.recording)
		tableView.reloadData()
	}
}

// MARK: - UITableViewDataSource

extension StoryPointDetailViewController: UITableViewDataSource {
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

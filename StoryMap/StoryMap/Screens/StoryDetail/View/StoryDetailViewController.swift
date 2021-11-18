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
    
    @ObservedObject private var viewModel: StoryDetailViewModel

    private let imageView = UIImageView()
    private let recordButton = UIButton(type: .custom)
    private let tableView = UITableView(frame: .zero, style: .plain)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setupUI() {
        title = viewModel.story.title
        view.backgroundColor = .white
        
        [imageView, tableView, recordButton].forEach(view.addSubview)
        
        setupNavBar()
        setupImageView()
        setupRecordButton()
        setupTableView()
        setupGestureRecognizer()
    }
    
    private func setupObservers() {
        stateObserver = viewModel.$state.sink { [weak self] state in
            self?.updateRecordButton(with: state)
            logger.info("DetailVC: stateObserver changed: \(state.rawValue)")
        }
        recordingsObserver = viewModel.$recordings.sink { [weak self] info in
            logger.info("DetailVC: recordingsObserver changed: \(info)")
            
            guard let self = self else { return }
            
            self.recordings = info
            
            guard !self.recordings.isEmpty else {
                self.tableView.isHidden = true
                return
            }
            
            self.tableView.isHidden = false
            self.tableView.reloadData()
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
            make.top.equalTo(imageView.snp.bottom).offset(StyleKit.metrics.padding.medium)
            make.width.height.equalTo(StyleKit.metrics.recordButtonSize)
        }
        
        recordButton.layer.cornerRadius = recordButton.frame.height / 2
        
        recordButton.clipsToBounds = false
        recordButton.layer.masksToBounds = false
        recordButton.layer.shouldRasterize = true
        
        recordButton.layer.shadowColor = UIColor.lightGray.cgColor
        recordButton.layer.shadowPath = UIBezierPath(roundedRect: recordButton.bounds, cornerRadius: recordButton.frame.height / 2).cgPath
        recordButton.layer.shadowOffset = .zero
        recordButton.layer.shadowRadius = StyleKit.metrics.padding.verySmall
        recordButton.layer.shadowOpacity = 0.7
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(recordButton.snp.bottom).offset(StyleKit.metrics.padding.medium)
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
            make.size.lessThanOrEqualTo(view.snp.width).multipliedBy(0.7)
            make.centerX.equalToSuperview()
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
            recordButton.backgroundColor = .white
            recordButton.tintColor = .gray
        case .inProgress:
            recordButton.backgroundColor = .red
            recordButton.tintColor = .white
        }
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
}

// MARK: - UITableViewDelegate

extension StoryDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = recordings[indexPath.row].recording
        viewModel.play(recording: recording)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        
        var content = cell.defaultContentConfiguration()
        content.text = cellData.recording.createdAt
        content.image = StyleKit.image.make(
            from: cellData.isPlaying ? StyleKit.image.icons.pause : StyleKit.image.icons.play,
            with: .alwaysTemplate
        )
        
        cell.contentConfiguration = content
        return cell
    }
}

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
    
    // MARK: - Observers
    
    private var stateObserver: AnyCancellable?
    
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
        
        [imageView, recordButton].forEach(view.addSubview)
        
        setupNavBar()
        setupImageView()
        setupRecordButton()
        setupGestureRecognizer()
    }
    
    private func setupObservers() {
        stateObserver = viewModel.$state.sink { [weak self] state in
            self?.updateRecordButton(with: state)
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
    
    private func setupGestureRecognizer() {
        let recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        recordButton.addGestureRecognizer(recognizer)
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(data: viewModel.story.image)
        
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.verySmall)
            make.width.height.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.width)
            make.centerX.equalToSuperview()
        }
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

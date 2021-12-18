//
//  DebugViewController.swift
//  StoryMap
//
//  Created by Felix Böhm on 28.11.21.
//

import Foundation
import UIKit
import Combine
import SwiftUI

class StoryListViewController: UIViewController {
    
    // MARK: - Private properties
    
    private var viewModel: StoryListViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)

    @ObservedObject private var locationManager: LocationManager

    private var subscribers = Set<AnyCancellable>()

    // MARK: - Initializers

    init(viewModel: StoryListViewModel, locationManager: LocationManager) {
        self.viewModel = viewModel
        self.locationManager = locationManager
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
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
	}
    
    // MARK: - Private methods
    
    private func setupUI() {
        title = "Stories"
        view.backgroundColor = .white
        
        [tableView].forEach(view.addSubview)
        
        setupNavBar()
        setupTableView()
    }
    
    private func setupSubscribers() {
        viewModel.$tableContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                logger.info("StoryListVC: Stories changed: \(data)")
                self?.tableView.reloadData()
            }
            .store(in: &subscribers)

        locationManager.$userLocation
            .receive(on: DispatchQueue.main)
            .assign(to: \.location, on: viewModel)
            .store(in: &subscribers)
    }

    private func setupNavBar() {
        let rightButton = UIBarButtonItem(
            image: StyleKit.image.make(from: StyleKit.image.icons.plus, with: .alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = rightButton
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
		tableView.estimatedRowHeight = StoryListCell.estimatedHeight
		tableView.register(StoryListCell.self, forCellReuseIdentifier: StoryListCell.reuseIdentifier)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.verySmall)
            make.leading.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
            make.bottom.equalToSuperview()
        }
    }

    @objc private func addButtonTapped() {
        guard let location = locationManager.userLocation else {
            // TODO: Add a warning if we don't have location permissions
            return
        }
        viewModel.addStory(with: location)
    }

    private func humanReadableTime(from timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YY-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - UITableViewDelegate

extension StoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.info("StoryListVC: Table didSelectRow \(indexPath)")
        viewModel.openStory(with: indexPath.row)
    }
}

// MARK: - UITableViewDataSource

extension StoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.tableContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: StoryListCell.reuseIdentifier) as? StoryListCell ?? StoryListCell()
        
		cell.update(with: viewModel.tableContent[indexPath.row])
        return cell
    }
}

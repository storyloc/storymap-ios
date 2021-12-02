//
//  MapViewController.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import Foundation
import UIKit
import Combine
import SwiftUI
import SnapKit

struct MapCollectionData {
	var cell: MapStoryThumbnailCell.Content
	var location: IndexLocation
}

class MapViewController: UIViewController {
    
    // MARK: - Constants
    
    private let listButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let centerButton = UIButton(type: .system)
    
    // MARK: - Variables
    
    @ObservedObject private var viewModel: MapViewModel
    @ObservedObject private var locationManager: LocationManager
    
    private lazy var mapView = locationManager.mapView
    private lazy var layout: UICollectionViewFlowLayout = makeLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    private var collectionViewHeightConstraint: Constraint?
    private var collectionViewLayoutPadding: CGFloat = 0
    private var autoScrolling = false
	private var collectionData: [MapCollectionData] = []
	
	private var selectedStoryIndex: Int = 0
    
	private var subscribers = Set<AnyCancellable>()
	private var storyInsertedSubscriber: AnyCancellable?
	
	private var storyToSelect: Story?
    
    // MARK: - Initializers
    
    init(viewModel: MapViewModel, locationManager: LocationManager) {
        self.viewModel = viewModel
        self.locationManager = locationManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
		
		storyInsertedSubscriber = viewModel.storyInsertedSubject
			.receive(on: DispatchQueue.main)
			.assign(to: \.storyToSelect, on: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
		setupSubscribers()
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.centerMap()
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		subscribers.forEach { $0.cancel() }
		subscribers.removeAll()
	}
    
    // MARK: - Private methods
    
    private func setupUI() {
        view.backgroundColor = .white
        
        [mapView, collectionView, listButton, addButton, centerButton].forEach(view.addSubview)
        
        setupCollectionView()
        setupListButton()
        setupAddButton()
        setupCenterButton()
        setupMap()

        updateAddButton(false)
        updateCenterButton(false)
    }
    
    private func setupSubscribers() {
		viewModel.$collectionData
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in
				self?.updateCollectionView(with: data)
				logger.info("MapVC: Observer collectionData changed: \(data)")
			}
			.store(in: &subscribers)
        
        locationManager.$userLocationAvailable
			.receive(on: DispatchQueue.main)
			.sink { [weak self] available in
				self?.updateAddButton(available)
				self?.viewModel.location = self?.locationManager.userLocation
            
				logger.info("MapVC: Observer userLocationAvailable changed: \(available)")
			}
			.store(in: &subscribers)
        
        locationManager.$userLocation
			.receive(on: DispatchQueue.main)
			.assign(to: \.location, on: viewModel)
			.store(in: &subscribers)
        
        locationManager.$isMapCentered
			.receive(on: DispatchQueue.main)
			.sink { [weak self] centered in
				self?.updateCenterButton(centered)
				logger.info("MapVC: Observer isMapCentered changed: \(centered)")
			}
			.store(in: &subscribers)
        
        locationManager.$selectedPinIndex
			.receive(on: DispatchQueue.main)
			.sink { [weak self] index in
				self?.selectStory(at: index)
				logger.info("MapVC: Observer selectedPinId changed: \(index)")
			}
			.store(in: &subscribers)
    }
	
	// MARK: - UI setup
    
    private func setupMap() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(MapStoryThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        
        collectionView.snp.makeConstraints { make in
			self.collectionViewHeightConstraint = make.height.equalTo(layout.itemSize.height + 2 * StyleKit.metrics.padding.small).constraint
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(StyleKit.metrics.padding.small)
            make.leading.trailing.equalToSuperview()
        }
		
		collectionViewHeightConstraint?.isActive = !collectionData.isEmpty
    }

    private func setupAddButton() {
        addButton.setImage(
            StyleKit.image.make(
                from: StyleKit.image.icons.plusCircle,
                with: .alwaysTemplate
            ),
            for: .normal
        )
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.backgroundColor = .white.withAlphaComponent(0.8)
        addButton.layer.cornerRadius = StyleKit.metrics.buttonHeight / 2

        addButton.snp.makeConstraints { make in
            make.bottom.equalTo(addButton.snp.top).offset(-StyleKit.metrics.padding.small)
            make.bottom.equalTo(collectionView.snp.top).offset(-StyleKit.metrics.padding.small)
            make.trailing.equalToSuperview().inset(StyleKit.metrics.padding.small)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
    }

    private func setupListButton() {
        listButton.setImage(
            StyleKit.image.make(
                from: StyleKit.image.icons.list,
                with: .alwaysTemplate
            ),
            for: .normal
        )
        listButton.addTarget(self, action: #selector(listButtonTapped), for: .touchUpInside)
        listButton.backgroundColor = .white.withAlphaComponent(0.8)
        listButton.layer.cornerRadius = StyleKit.metrics.buttonHeight / 2
		listButton.layer.borderWidth = 1.5
		listButton.layer.borderColor = UIColor.systemBlue.cgColor
		listButton.imageView?.contentMode = .scaleAspectFit
		listButton.imageEdgeInsets = UIEdgeInsets(
			top: StyleKit.metrics.padding.small,
			left: StyleKit.metrics.padding.small,
			bottom: StyleKit.metrics.padding.small,
			right: StyleKit.metrics.padding.small
		)

        listButton.snp.makeConstraints { make in
            make.centerX.equalTo(addButton)
            make.bottom.equalTo(addButton.snp.top).offset(-StyleKit.metrics.padding.small)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
    }
    
    private func setupCenterButton() {
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
		centerButton.backgroundColor = .white.withAlphaComponent(0.8)
        centerButton.layer.cornerRadius = StyleKit.metrics.buttonHeight / 2
        
        centerButton.snp.makeConstraints { make in
            make.centerX.equalTo(addButton)
            make.bottom.equalTo(listButton.snp.top).offset(-StyleKit.metrics.padding.small)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
    }
	
	private func makeLayout() -> UICollectionViewFlowLayout {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = .greatestFiniteMagnitude
		layout.minimumLineSpacing = StyleKit.metrics.padding.small
		layout.estimatedItemSize = .zero
		
		let size = (view.bounds.width - 2 * StyleKit.metrics.padding.small) / 2
		layout.itemSize = CGSize(width: size, height: size)

        // Center first and last item
        collectionViewLayoutPadding = (view.bounds.width - size) / 2
		layout.sectionInset = UIEdgeInsets(
			top: StyleKit.metrics.padding.small,
			left: collectionViewLayoutPadding,
			bottom: StyleKit.metrics.padding.small,
			right: collectionViewLayoutPadding
		)
		return layout
	}
	
	// MARK: - UI updates
	
	private func selectStory(at index: Int) {
		guard !collectionData.isEmpty else {
			return
		}
		
		collectionView.reloadData()

		if index != selectedStoryIndex {
            self.autoScrolling = true
            logger.info("AutoScrolling: \(self.autoScrolling)")
			collectionView.scrollToItem(
				at: IndexPath(row: index, section: 0),
				at: .centeredHorizontally,
				animated: true
            )
			selectedStoryIndex = index
		}
	}
	
	private func updateCollectionView(with data: [MapCollectionData]) {
		collectionViewHeightConstraint?.isActive = !data.isEmpty
		collectionData = data
		collectionView.reloadData()
		addStoriesToMap()
		
		if let story = storyToSelect,
		   let index = collectionData.firstIndex(where: { $0.location.cid == story.id.stringValue }) {
			locationManager.selectMarker(at: index)
			storyToSelect = nil
		}
	}
    
    private func updateAddButton(_ enabled: Bool) {
        addButton.isEnabled = enabled
    }
    
    private func updateCenterButton(_ centered: Bool) {
        let iconName = centered ? StyleKit.image.icons.centerOn : StyleKit.image.icons.centerOff
        centerButton.setImage(StyleKit.image.make(from: iconName), for: .normal)
    }

    func addStoriesToMap() {
		guard !collectionData.isEmpty else { return }
        let locations = collectionData.map { $0.location }
		locationManager.addMarkers(to: locations)
        
        logger.info("MapVC: addStoriesToMap")
    }
    
    // MARK: - Button actions
    
    @objc private func listButtonTapped() {
        viewModel.openStoryList()
    }

    @objc private func centerButtonTapped() {
        locationManager.centerMap()
        
        logger.info("MapVC centerMap")
    }
    
    @objc private func addButtonTapped() {
        guard let location = locationManager.userLocation else {
            // TODO: Add a warning if we don't have location permissions
            return
        }
        viewModel.addStory(with: location)
    }
}

// MARK: - UICollectionViewDelegate & UICollectionViewDataSource

extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		logger.info("MapVC: collectionView didSelectItem \(indexPath.row): \(self.collectionData[indexPath.row].location.cid)")
        
        if locationManager.selectedPinIndex == indexPath.row {
            viewModel.openStory(with: indexPath.row)
        } else {
			locationManager.selectMarker(at: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as? MapStoryThumbnailCell ?? MapStoryThumbnailCell()
     
		cell.update(with: collectionData[indexPath.row].cell)
        cell.select(indexPath.row == locationManager.selectedPinIndex)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if autoScrolling {
            return
        }
        let pos = Int(scrollView.contentOffset.x)

        let padding = Int(collectionViewLayoutPadding)
        let screenSize = view.bounds.width
        let lateration = Int(screenSize / 2) - padding

        let spacing = Int(StyleKit.metrics.padding.small)
        let width = Int(layout.itemSize.width) + spacing

        var id = Int((pos + lateration) / (width))
		
		if id < 0 {
			id = 0
		} else if id >= collectionData.count {
			id = collectionData.count - 1
		}
		
        logger.info("Did Scroll: \(pos) \(id)")

        locationManager.selectMarker(at: id)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.autoScrolling = false
        logger.info("AutoScrolling did end: \(self.autoScrolling)")
    }
}

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

class MapViewController: UIViewController {
    
    // MARK: - Constants
    
    private let addButton = UIButton(type: .system)
    private let centerButton = UIButton(type: .system)
    
    // MARK: - Variables
    
    @ObservedObject private var viewModel: MapViewModel
    @ObservedObject private var locationManager: LocationManager
    
    private lazy var mapView = locationManager.mapView
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: StyleKit.metrics.thumbnailSize, height: StyleKit.metrics.thumbnailSize)
        layout.minimumInteritemSpacing = .greatestFiniteMagnitude
        layout.minimumLineSpacing = StyleKit.metrics.padding.small
        layout.estimatedItemSize = .zero
        
        layout.sectionInset = UIEdgeInsets(
            top: StyleKit.metrics.padding.small,
            left: StyleKit.metrics.padding.small,
            bottom: StyleKit.metrics.padding.small,
            right: StyleKit.metrics.padding.small
        )
        return layout
    }()
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    private var collectionViewHeightConstraint: NSLayoutConstraint?
    private var collectionData: [Story] = []
    
    // MARK: - Subscribers
    
    private var isMapCenteredSubscriber: AnyCancellable?
    private var userLocAvailableSubscriber: AnyCancellable?
    private var selectedPinIdSubscriber: AnyCancellable?
    private var collectionDataSubscriber: AnyCancellable?
    private var userLocationSubscriber: AnyCancellable?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.centerMap()
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        view.backgroundColor = .white
        
        [mapView, collectionView, addButton, centerButton].forEach(view.addSubview)
        
        setupCollectionView()
        setupAddButton()
        setupCenterButton()
        setupMap()
        
        setupObservers()
        
        updateAddButton(false)
        updateCenterButton()
    }
    
    private func setupObservers() {
        collectionDataSubscriber = viewModel.$collectionData.sink { [weak self] data in
            guard let self = self else { return }
            print("MVC:Observer collectionData changed")
            self.collectionViewHeightConstraint?.isActive = !data.isEmpty
            self.collectionData = data
            self.collectionView.reloadData()
            self.addStoriesToMap()
            print("---- viewModel")
        }
        
        userLocAvailableSubscriber = locationManager.$userLocationAvailable.sink(receiveValue: { [weak self] available in
            print("MVC:Observer userLocationAvailable changed: \(available), \(self?.locationManager.userLocationAvailable), \(self?.locationManager.userLocation)")
            
            self?.updateCenterButton()
            self?.updateAddButton(available)
            
            self?.viewModel.location = self?.locationManager.userLocation
            print("---- locationManager")
        })
        
        userLocationSubscriber = locationManager.$userLocation.assign(to: \.location, on: viewModel)
        
        isMapCenteredSubscriber = locationManager.$isMapCentered.sink(receiveValue: { [weak self] _ in
            print("MVC:Observer isMapCentered changed")
            self?.updateCenterButton()
            print("---- locationManager")
        })
        
        selectedPinIdSubscriber = locationManager.$selectedPinId.sink(receiveValue: { [weak self] index in
            print("MVC:Observer selectedPinId changed")
            
            guard !(self?.collectionData.isEmpty ?? true) else {
                return
            }
            
            self?.collectionView.reloadData()
            self?.collectionView.scrollToItem(
                at: IndexPath(row: index, section: 0),
                at: .centeredHorizontally,
                animated: true
            )
            print("---- locationManager")
        })
    }
    
    private func setupMap() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: StyleKit.metrics.thumbnailSize + 2 * StyleKit.metrics.padding.small)
        collectionViewHeightConstraint?.isActive = !collectionData.isEmpty
        
        collectionView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(StyleKit.metrics.padding.medium)
            make.leading.trailing.equalToSuperview()
        }
    }
 
    private func setupAddButton() {
        addButton.setImage(
            StyleKit.image.make(
                from: StyleKit.image.icons.plus,
                with: .alwaysTemplate
            ),
            for: .normal
        )
        
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.accessibilityIdentifier = "Add Story Button"
        
        addButton.snp.makeConstraints { make in
            make.bottom.equalTo(collectionView.snp.top).offset(-StyleKit.metrics.padding.medium)
            make.trailing.equalToSuperview().inset(StyleKit.metrics.padding.medium)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
    }
    
    private func setupCenterButton() {
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        
        centerButton.snp.makeConstraints { make in
            make.centerX.equalTo(addButton)
            make.bottom.equalTo(addButton.snp.top).offset(-StyleKit.metrics.padding.small)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
        
        updateCenterButton()
    }
    
    func updateAddButton(_ enabled: Bool) {
        addButton.isEnabled = enabled
    }
    
    func updateCenterButton() {
        let iconName = locationManager.isMapCentered ? StyleKit.image.icons.centerOn : StyleKit.image.icons.centerOff
        centerButton.setImage(StyleKit.image.make(from: iconName), for: .normal)
    }

    func addStoriesToMap() {
        let locations: [IndexLocation] = collectionData.map { item in
            (cid: item.id.stringValue, location: item.loc)
        }
        print("MVC:addStoriesToMap")
        locationManager.addMarkers(to: locations)
    }
    
    // MARK: - Button actions
    
    @objc private func centerButtonTapped() {
        locationManager.isMapCentered = !locationManager.isMapCentered
        updateCenterButton()
        print("Center Map, isMapCentered: \(locationManager.isMapCentered)")
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
        print("MVC:cV didSelectItem \(indexPath.row): \(collectionData[indexPath.row].id)")
        // TODO: Uncomment after testing
        // viewModel.openStory(with: indexPath.row)
        locationManager.selectMarker(with: collectionData[indexPath.row].id.stringValue)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as? ThumbnailCell ?? ThumbnailCell()
        let cellData = collectionData[indexPath.row]
        
        cell.update(with: UIImage(data: cellData.image))
        cell.select(indexPath.row == locationManager.selectedPinId)
        return cell
    }
}

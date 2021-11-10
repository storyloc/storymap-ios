//
//  MapViewController.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    // MARK: - Variables
    
    private var viewModel: MapViewModelType
    
    // MARK: - Constants
    
    private let addButton = UIButton(type: .system)
    private let centerButton = UIButton(type: .system)
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    private var currentLocation: Location? {
        didSet {
            updateAddButton()
        }
    }
    
    var collectionView: UICollectionView!
    
    // MARK: - Initializers
    
    init(viewModel: MapViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestLocationPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        viewModel.onUpdate = { [weak self] in
            self?.collectionView.reloadData()
            // TODO: Add only stories in current region 
            self?.addStoriesToMap()
        }
        
        view.backgroundColor = .white
        setupCollectionView()
        setupAddButton()
        setupCenterButton()
        setupMap()
    }
    
    private func requestLocationPermissions() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupMap() {
        view.addSubview(mapView)
        mapView.showsUserLocation = true
        mapView.camera.centerCoordinateDistance = 100
        mapView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(addButton.snp.top).offset(-StyleKit.metrics.padding.large)
        }
        
        addStoriesToMap()
    }
    
    private func setupCollectionView() {
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
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        
        
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.verySmall)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(StyleKit.metrics.thumbnailSize + 2 * StyleKit.metrics.padding.small)
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
        addButton.backgroundColor = .white
        
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.accessibilityIdentifier = "Add Story Button"
        view.addSubview(addButton)
        
        addButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(StyleKit.metrics.padding.medium)
            make.trailing.equalToSuperview().inset(StyleKit.metrics.padding.large)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
        
        updateAddButton()
    }
    
    private func setupCenterButton() {
        centerButton.setTitle("Center Map", for: .normal)
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        
        view.addSubview(centerButton)
        centerButton.snp.makeConstraints { make in
            make.centerY.equalTo(addButton)
            make.leading.equalToSuperview().offset(StyleKit.metrics.padding.large)
        }
    }
    
    func updateAddButton() {
        addButton.isEnabled = currentLocation != nil
    }
    
    func centerMap() {
        if let currentLocation = currentLocation {
            mapView.setRegion(currentLocation.region(), animated: true)
        }
    }
    
    func addStoriesToMap() {
        viewModel.collectionData.forEach { story in
            guard let location = story.location else { return }
            let marker = MKPointAnnotation()
            marker.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            mapView.addAnnotation(marker)
        }
    }
    
    // MARK: - Button actions
    
    @objc private func centerButtonTapped() {
        centerMap()
    }
    
    @objc private func addButtonTapped() {
        viewModel.addStory(with: currentLocation!)
    }
}

// MARK: - UICollectionViewDelegate & UICollectionViewDataSource

extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.openStory(with: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as? ThumbnailCell ?? ThumbnailCell()
        let cellData = viewModel.collectionData[indexPath.row]
        cell.update(with: UIImage(data: cellData.image))
        return cell
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: break
        default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = Location(location: location)
            centerMap()
        }
    }
}

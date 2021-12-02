//
//  LocationManager.swift
//  StoryMap
//
//  Created by Dory on 12/11/2021.
//

import Foundation
import MapKit
import CoreLocation
import Combine

typealias IndexLocation = (cid: String, location: Location)

protocol LocationManagerType: CLLocationManagerDelegate, MKMapViewDelegate {
    var mapView: MKMapView { get }
    var isMapCentered: Bool { get }
    var userLocationAvailable: Bool { get }
    var userLocation: Location? { get }
    var selectedPinIndex: Int { get }
    
    func centerMap()
    func selectMarker(at index: Int)
    func addMarkers(to locations: [IndexLocation])
}

class LocationManager: NSObject, ObservableObject, LocationManagerType {
    let mapView = MKMapView()
    
    @Published var userLocation: Location?
    @Published var isMapCentered: Bool = true
    @Published var userLocationAvailable: Bool = false
	@Published var selectedPinIndex: Int = Int.max
    
    private let locationManager = CLLocationManager()
    private var pinLocations: [IndexLocation] = []
	private var annotations: [MapAnnotation] = []
    
    private var mapCenterLocation = Location(latitude: 21.282778, longitude: -157.829444) //Honululu
    private var mapRegionChanging = false
    private var centeringMap = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    func centerMap() {
        guard let userLocation = userLocation else {
            return
        }
        
        mapView.setCenter(userLocation.clLocation2D, animated: true)
        isMapCentered = true
        
        logger.info("LocManager: centerMap")
    }
    
    func selectMarker(at index: Int) {
		if selectedPinIndex != index {
			selectedPinIndex = index
            if annotations.count > index {
                mapView.selectAnnotation(annotations[index], animated: true)
                if !isMapCentered, !mapRegionChanging {
                    mapView.setCenter(annotations[index].coordinate, animated: true)
                }
                logger.info("LocManager: selectedMarker, \(index)")
            } else {
                logger.info("LocManager: selectedMarker, \(index) Out of Bound")
            }
		}
    }
    
    func addMarkers(to locations: [IndexLocation]) {
        pinLocations = locations
        
        // remove existing Annotations to not have them twice
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
		annotations.removeAll()

        guard !pinLocations.isEmpty else {
            return
        }
        
        pinLocations.forEach { loc in
			guard let center = userLocation else {
				return
			}
			
            let distance = Int(loc.location.distance(from: center))
            let distanceString = distance > 1000
                ? "\(Double(round(Double(distance/100))/10))km"
                : "\(distance)m"

			let annotation = MapAnnotation(
				cid: loc.cid,
				title: distanceString,
				coordinate: CLLocationCoordinate2D(
					latitude: loc.location.latitude,
					longitude: loc.location.longitude
				)
			)
            
			annotations.append(annotation)
            mapView.addAnnotation(annotation)
        }
        
        logger.info("LocManager: addMarkers, annotations: \(self.mapView.annotations.count)")
        
        if selectedPinIndex >= pinLocations.count {
            selectMarker(at: 0)
			return
        }
        
        selectMarker(at: selectedPinIndex)
    }
}

// MARK: MKMapViewDelegate

extension LocationManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapRegionChanging = true
        if !centeringMap {
            isMapCentered = false
        }
        logger.info("LocManager: regionWillChangeAnimated")
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegionChanging = false
        centeringMap = false
        logger.info("LocManager: regionDidChangeAnimated, isMapCentered: \(self.isMapCentered)")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        logger.info("LocManager: didSelectMarker")
        
        guard let annotation = view.annotation as? MapAnnotation else {
            return
        }
        
		if let index = pinLocations.firstIndex(where: { $0.cid == annotation.cid }) {
            selectedPinIndex = index
        }
        
        logger.info("LocManager: selectedPin: \(self.selectedPinIndex): \(self.pinLocations[self.selectedPinIndex].cid)")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // TODO: React to user not giving location permissions.
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: break
        default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
			userLocation = Location(location: location)
			
			guard let userLocation = userLocation else { return }
			
			if !userLocationAvailable {
				userLocationAvailable = true
                centeringMap = true
				mapView.setRegion(userLocation.region(), animated: true)
				logger.info("LocManager: didUpdateLocations location init")
			}
			
			if isMapCentered, !mapRegionChanging {
                let distance = mapCenterLocation.distance(from: userLocation).rounded()
                if distance > 1 {
                    centeringMap = true
                    mapCenterLocation = Location(
                        latitude: mapView.centerCoordinate.latitude,
                        longitude: mapView.centerCoordinate.longitude
                    )
                    mapView.setRegion(userLocation.region(span: mapView.region.span), animated: true)
                }
				logger.info("LocManager: didUpdateLocations center region \(distance)")
			}
        }
    }
}

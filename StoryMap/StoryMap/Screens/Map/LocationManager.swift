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

typealias IndexLocation = (index: String, location: Location)

protocol LocationManagerType: CLLocationManagerDelegate, MKMapViewDelegate {
    var mapView: MKMapView { get }
    var isMapCentered: Bool { get }
    var userLocationAvailable: Bool { get }
    var userLocation: Location? { get }
    var mapCenterLocation: Location? { get }
    var selectedPinIndex: Int { get }
    
    func centerMap()
    func selectMarker(with index: String)
    func addMarkers(to locations: [IndexLocation])
}

class LocationManager: NSObject, ObservableObject, LocationManagerType {
    let mapView = MKMapView()
    var userLocation: Location?
    var mapCenterLocation: Location?
    
    @Published var isMapCentered: Bool = true
    @Published var userLocationAvailable: Bool = false
    @Published var selectedPinIndex: Int = 0
    
    private let locationManager = CLLocationManager()
    private var pinLocations: [IndexLocation] = []
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.camera.centerCoordinateDistance = 500
    }
    
    func centerMap() {
        guard let userLocation = userLocation else {
            return
        }

        mapView.setRegion(userLocation.region(), animated: true)
        isMapCentered = true
    }
    
    func selectMarker(with index: String) {
        if let annotation = mapView.annotations.first(where: { $0.title == index }) {
            mapView.selectAnnotation(annotation, animated: true)
            selectedPinIndex = pinLocations.firstIndex(where: { $0.index == index }) ?? 0
        }
    }
    
    func addMarkers(to locations: [IndexLocation]) {
        pinLocations = locations
        locations.forEach { loc in
            let marker = MKPointAnnotation()
            marker.coordinate = CLLocationCoordinate2D(latitude: loc.location.latitude, longitude: loc.location.longitude)
            marker.title = loc.index
            mapView.addAnnotation(marker)
        }
    }
}

// MARK: MKMapViewDelegate

extension LocationManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapCenterLocation = Location(
            latitude: mapView.centerCoordinate.latitude,
            longitude: mapView.centerCoordinate.longitude
        )
        isMapCentered = mapCenterLocation == userLocation
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapCenterLocation = Location(
            latitude: mapView.centerCoordinate.latitude,
            longitude: mapView.centerCoordinate.longitude
        )
        
        if let userLocation = userLocation,
           let mapCenterLocation = mapCenterLocation,
           mapCenterLocation.distance(from: userLocation).rounded() > 0 {
            print(mapCenterLocation.distance(from: userLocation))
            isMapCentered = false
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
    
        let location = Location(
            latitude: annotation.coordinate.latitude,
            longitude: annotation.coordinate.longitude
        )
        if let index = pinLocations.firstIndex(where: { $0.index == annotation.title
        }) {
            selectedPinIndex = index
        } else {
            print(location)
            print(pinLocations)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: break
        default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = Location(location: location)
            userLocationAvailable = true
            
            if isMapCentered {
                centerMap()
            }
        }
    }
}
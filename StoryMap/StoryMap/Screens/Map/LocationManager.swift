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
    var selectedPinId: Int { get }
    
    func centerMap()
    func selectMarker(with cid: String)
    func addMarkers(to locations: [IndexLocation])
}

class LocationManager: NSObject, ObservableObject, LocationManagerType {
    let mapView = MKMapView()
    var userLocation: Location?
    
    @Published var isMapCentered: Bool = true
    @Published var userLocationAvailable: Bool = false
    @Published var selectedPinId: Int = 0
    
    private let locationManager = CLLocationManager()
    private var pinLocations: [IndexLocation] = []
    
    private var mapCenterLocation = Location(latitude: 21.282778, longitude: -157.829444) //Honululu
    
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
        print("centerMap")
    }
    
    func selectMarker(with cid: String) {
        if let annotation = mapView.annotations.first(where: { $0.title == cid }) {
            mapView.selectAnnotation(annotation, animated: true)
            selectedPinId = pinLocations.firstIndex(where: { $0.cid == cid }) ?? 0
        }
        print("Select Marker, \(cid): \(selectedPinId)")
    }
    
    func addMarkers(to locations: [IndexLocation]) {
        pinLocations = locations
        
        // remove existing Annotations to not have them twice
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)

        pinLocations.forEach { loc in
            let marker = MKPointAnnotation()
            
            marker.title = loc.cid
            marker.coordinate = CLLocationCoordinate2D(
                latitude: loc.location.latitude,
                longitude: loc.location.longitude
            )
            
            mapView.addAnnotation(marker)
        }
        print("LM:addMarkers, annotations: \(mapView.annotations.count)")
    }
}

// MARK: MKMapViewDelegate

extension LocationManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapCenterLocation = Location(
            latitude: mapView.centerCoordinate.latitude,
            longitude: mapView.centerCoordinate.longitude
        )
        
        var distance = 0.1
        if let userLocation = userLocation {
            distance = mapCenterLocation.distance(from: userLocation).rounded()
            if distance > 0.0 {
                isMapCentered = false
            }
        }
        print("Move Map, isMapCentered: \(isMapCentered), distance: \(distance)")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        print("LM:didSelect")
        
        if let index = pinLocations.firstIndex(where: { $0.cid == annotation.title }) {
            selectedPinId = index
        }
        print("Selected Pin: \(selectedPinId): \(pinLocations[selectedPinId].cid)")
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

            if !userLocationAvailable, let userLocation = userLocation {
                userLocationAvailable = true
                mapView.setRegion(userLocation.region(), animated: true)
            }

            if isMapCentered {
                centerMap()
            }
        }
    }
}

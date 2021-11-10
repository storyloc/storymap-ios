//
//  Location.swift
//  StoryMap
//
//  Created by Dory on 10/11/2021.
//

import Foundation
import MapKit
import CoreLocation
import RealmSwift

class Location: EmbeddedObject {
    @Persisted var latitude: Double
    @Persisted var longitude: Double
    
    convenience init(location: CLLocation) {
        self.init()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
    
    func region(latDelta: Double = 0.01, lonDelta: Double = 0.01) -> MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }
}

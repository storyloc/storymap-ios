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
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    var clLocation2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    convenience init(latitude: Double, longitude: Double) {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
    }
    
    convenience init(location: CLLocation) {
        self.init()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
    
    func region(latDelta: Double = 0.05, lonDelta: Double = 0.05) -> MKCoordinateRegion {
        return MKCoordinateRegion(center: clLocation2D, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }
    
    func distance(from location: Location) -> Double {
        return clLocation.distance(from: location.clLocation)
    }
    
    func randomize() -> Location {
        return Location(
            latitude: latitude + (Double.random(in: 0...99) / 10000),
            longitude: longitude + (Double.random(in: 0...99) / 10000)
        )
    }
}

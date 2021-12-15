//
//  MapMarker.swift
//  StoryMap
//
//  Created by Dory on 27/11/2021.
//

import MapKit

final class MapAnnotation: NSObject, MKAnnotation {
	var cid: String
	var title: String?
    var subtitle: String?
	var coordinate: CLLocationCoordinate2D
	
    init(cid: String, title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
		self.cid = cid
		self.title = title
        self.subtitle = subtitle
		self.coordinate = coordinate
	}
}

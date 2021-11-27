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
	var coordinate: CLLocationCoordinate2D
	
	init(cid: String, title: String?, coordinate: CLLocationCoordinate2D) {
		self.cid = cid
		self.title = title
		self.coordinate = coordinate
	}
}
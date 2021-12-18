//
//  StoryPoint.swift
//  StoryMap
//
//  Created by Dory on 18/12/2021.
//

import Foundation
import RealmSwift
import UIKit

class StoryPoint: Object {
	@Persisted var id: ObjectId
	@Persisted var timestamp: Date
	@Persisted var image: Data
	@Persisted var location: Location?
	@Persisted var audioRecordings: List<AudioRecording>
	@Persisted var story = LinkingObjects(fromType: Story.self, property: "collection")
	
	var loc: Location {
		return location!
	}
	
	var uiImage: UIImage? {
		UIImage(data: image)
	}
	
	convenience init(image: Data, location: Location) {
		self.init()
		self.timestamp = Date()
		self.image = image
		self.location = location
	}
}

//
//  Story.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import RealmSwift
import UIKit

class Story: Object {
    @Persisted var id: ObjectId
    @Persisted var title: String
    @Persisted var timestamp: Date
	@Persisted var collection: List<StoryPoint>
	
	var mainImage: UIImage? {
		Array(collection).first?.uiImage
	}
	
	var mainLocation: Location {
		Array(collection).first?.loc ?? Location.defaultLocation
	}
	
	var allRecordings: [AudioRecording] {
		var recs: [AudioRecording] = []
		collection.forEach { point in
			point.audioRecordings.forEach { rec in
				recs.append(rec)
			}
		}
		return recs
	}
	
	var allTags: [Tag] {
		var tags: [Tag] = []
		collection.forEach { point in
			tags.append(contentsOf: point.tagArray)
		}
		return tags
	}
    
    convenience init(title: String, collection: [StoryPoint]) {
        self.init()
        self.title = title
        self.timestamp = Date()
		self.collection.append(objectsIn: collection)
    }
}

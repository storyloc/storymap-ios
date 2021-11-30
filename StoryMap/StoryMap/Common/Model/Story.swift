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
    @Persisted var image: Data
    @Persisted var location: Location?
    @Persisted var audioRecordings: List<AudioRecording>
    
    var loc: Location {
        return location!
    }
	
	var uiImage: UIImage? {
		UIImage(data: image)
	}
    
    convenience init(title: String, image: Data, location: Location) {
        self.init()
        self.title = title
        self.timestamp = Date()
        self.image = image
        self.location = location
    }
}

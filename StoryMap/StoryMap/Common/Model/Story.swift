//
//  Story.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import RealmSwift

class Story: Object {
    @Persisted var id: ObjectId
    @Persisted var title: String
    @Persisted var timestamp: Date
    @Persisted var image: Data
    @Persisted var location: Location?
    
    var loc: Location {
        return location!
    }
    
    convenience init(title: String, image: Data, location: Location) {
        self.init()
        self.title = title
        self.timestamp = Date()
        self.image = image
        self.location = location
    }
}

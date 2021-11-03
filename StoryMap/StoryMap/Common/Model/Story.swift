//
//  Story.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import RealmSwift

class Story: Object {
    @Persisted var title: String
    @Persisted var timestamp: Date
    @Persisted var image: Data
    
    convenience init(title: String, image: Data) {
        self.init()
        self.title = title
        self.timestamp = Date()
        self.image = image
    }
}

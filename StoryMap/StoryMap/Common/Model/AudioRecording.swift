//
//  AudioRecording.swift
//  StoryMap
//
//  Created by Dory on 18/11/2021.
//

import Foundation
import RealmSwift

class AudioRecording: Object {
    @Persisted var id: ObjectId
    @Persisted var fileName: String
    @Persisted var length: Double
    @Persisted var createdAt: String
    var story = LinkingObjects(fromType: Story.self, property: "audioRecordings")
    
    convenience init(fileName: String, length: Double) {
        self.init()
        self.fileName = fileName
        self.length = length
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        self.createdAt = dateFormatter.string(from: Date())
    }
}

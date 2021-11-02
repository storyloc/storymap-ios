//
//  StoryDetailViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation

protocol StoryDetailViewModelType: AnyObject {
    
}

class StoryDetailViewModel: StoryDetailViewModelType {
    var story: Story
    
    init(story: Story) {
        self.story = story
    }
}

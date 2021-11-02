//
//  MapViewModel.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation

protocol MapViewModelType: AnyObject {
    func addStory()
}

class MapViewModel: MapViewModelType {
    var onAddStory: (() -> Void)?
    
    func addStory() {
        onAddStory?()
    }
}

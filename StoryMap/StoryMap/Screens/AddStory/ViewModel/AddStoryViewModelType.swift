//
//  AddStoryViewModelType.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation

enum PhotoInputType {
    case camera
    case photoLibrary
}

protocol AddStoryViewModelType: AnyObject {
    var titlePlaceholder: String { get }
    var title: String? { get set }
    var titleError: String { get }
    
    var addPhotoTitle: String { get }
    
    var confirmTitle: String { get }
    var confirmButtonEnabled: Bool { get }
    
    var image: Data? { get set }
    
    func showPhotoAlert()
    func capturePhoto()
    func confirm()
    func close()
}

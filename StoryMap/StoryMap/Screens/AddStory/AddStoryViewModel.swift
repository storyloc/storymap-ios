//
//  AddStoryViewModel.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation

protocol AddStoryViewModelType: AnyObject {
    var titlePlaceholder: String { get }
    var title: String? { get set }
    var titleError: String { get }
    var locationPlaceholder: String { get }
    var recordIcon: String { get }
    var addPhotoTitle: String { get }
    var addPhotoDialogueTitle: String { get }
    var confirmTitle: String { get }
}

class AddStoryViewModel: AddStoryViewModelType {
    let titlePlaceholder: String = "Add Title"
    var title: String?
    var titleError: String {
        get {
            return title?.isEmpty ?? true ? "Title should not be empty." : " "
        }
    }
    
    let locationPlaceholder: String = "Add Location"
    let recordIcon: String = "record"
    let addPhotoTitle: String = "Add Photo"
    var addPhotoDialogueTitle: String = "Do you want to take a new photo or choose from library instead?"
    let confirmTitle: String = "Create Story"
}

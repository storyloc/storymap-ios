//
//  AddStoryViewModel.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

protocol AddStoryViewModelType: AnyObject {
    var titlePlaceholder: String { get }
    var title: String? { get set }
    var titleError: String { get }
    
    var locationPlaceholder: String { get }
    var recordIcon: String { get }
    
    var addPhotoTitle: String { get }
    var addPhotoDialogueTitle: String { get }
    var addPhotoCaptureAction: String { get }
    var addPhotoChooseAction: String { get }
    
    var confirmTitle: String { get }
    
    func showAlert(_ alert: UIAlertController)
}

class AddStoryViewModel: AddStoryViewModelType {
    let titlePlaceholder: String = LocalizationKit.addStory.titlePlaceholder
    var title: String?
    var titleError: String {
        get {
            return title?.isEmpty ?? true ? LocalizationKit.addStory.titleError : " "
        }
    }
    
    let locationPlaceholder: String = LocalizationKit.addStory.locationPlaceholder
    let recordIcon: String = StyleKit.image.icons.record
    let addPhotoTitle: String = LocalizationKit.addStory.addPhotoButtonTitle
    let addPhotoDialogueTitle: String = LocalizationKit.addStory.addPhotoDialogueTitle
    let addPhotoCaptureAction: String = LocalizationKit.addStory.addPhotoCaptureAction
    let addPhotoChooseAction: String = LocalizationKit.addStory.addPhotoChooseAction
    let confirmTitle: String = LocalizationKit.addStory.confirmButtonTitle
    
    var onShowAlert: ((UIAlertController) -> Void)?
    
    func showAlert(_ alert: UIAlertController) {
        onShowAlert?(alert)
    }
}

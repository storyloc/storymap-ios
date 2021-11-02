//
//  AddStoryViewModel.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation

class AddStoryViewModel: AddStoryViewModelType {
    let titlePlaceholder: String = LocalizationKit.addStory.titlePlaceholder
    let locationPlaceholder: String = LocalizationKit.addStory.locationPlaceholder
    let recordIcon: String = StyleKit.image.icons.record
    
    let addPhotoTitle: String = LocalizationKit.addStory.addPhotoButtonTitle
    let confirmTitle: String = LocalizationKit.addStory.confirmButtonTitle
    
    var title: String?
    var titleError: String {
        get {
            return title?.isEmpty ?? true ? LocalizationKit.addStory.titleError : " "
        }
    }
    
    var image: Data?
    
    var onShowAlert: ((AlertConfig) -> Void)?
    var onShowImagePicker: ((PhotoInputType) -> Void)?
    var onConfirm: ((Story) -> Void)?
    
    private let realmDataProvider = RealmDataProvider.shared
    
    func showPhotoAlert() {
        let alert = AlertConfig(
            title: LocalizationKit.addStory.addPhotoDialogueTitle,
            message: nil,
            style: .actionSheet,
            actions: [
                AlertAction(
                    title: LocalizationKit.addStory.addPhotoCaptureAction,
                    style: .default,
                    handler: { [weak self] in
                        self?.onShowImagePicker?(.camera)
                    }
                ),
                AlertAction(
                    title: LocalizationKit.addStory.addPhotoChooseAction,
                    style: .default,
                    handler: { [weak self] in
                        self?.onShowImagePicker?(.photoLibrary)
                    }
                ),
                AlertAction(
                    title: LocalizationKit.general.cancel,
                    style: .cancel,
                    handler: nil
                )
            ]
        )
        
        onShowAlert?(alert)
    }
    
    func confirm() {
        guard let title = title, let image = image else {
            // TODO: Add error handling.
            return
        }
        
        let story = Story(title: title, image: image)
        realmDataProvider.write(object: story)
        onConfirm?(story)
    }
}

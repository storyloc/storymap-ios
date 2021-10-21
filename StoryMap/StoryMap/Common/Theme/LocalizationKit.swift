//
//  LocalizationKit.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation

struct LocalizationKit {
    static let general = General()
    static let addStory = AddStory()}

extension LocalizationKit {
    struct General {
        let cancel = "general_cancel".localized
        let close = "general_close".localized
    }

    struct AddStory {
        let titlePlaceholder = "addStory_titleTextField_placeholder".localized
        let titleError = "addStory_titleTextField_error".localized
        let locationPlaceholder = "addStory_locationTextField_placeholder".localized
        let addPhotoButtonTitle = "addStory_addPhoto_buttonTitle".localized
        let addPhotoDialogueTitle = "addStory_addPhoto_dialogueTitle".localized
        let addPhotoCaptureAction = "addStory_addPhoto_captureAction".localized
        let addPhotoChooseAction = "addStory_addPhoto_chooseAction".localized
        let confirmButtonTitle = "addStory_confirmButton_title".localized
    }
}

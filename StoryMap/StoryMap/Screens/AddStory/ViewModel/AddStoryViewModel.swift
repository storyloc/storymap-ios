//
//  AddStoryViewModel.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation

final class AddStoryViewModel: AddStoryViewModelType {
    let titlePlaceholder: String = LocalizationKit.addStory.titlePlaceholder
    
    let confirmTitle: String = LocalizationKit.addStory.confirmButtonTitle
    
    var location: Location
    
    var title: String? = ""
    
    var titleError: String {
        get {
            title?.isEmpty ?? true ? LocalizationKit.addStory.titleError : " "
        }
    }
    
    var addPhotoTitle: String {
        get {
            image == nil ? LocalizationKit.addStory.addPhotoButtonTitle : LocalizationKit.addStory.replacePhotoButtonTitle
        }
    }
    
    var confirmButtonEnabled: Bool {
        get {
            !(title?.isEmpty ?? true) && image != nil
        }
    }
    
    var image: Data?
    
    var onShowAlert: ((AlertConfig) -> Void)?
    var onShowImagePicker: ((PhotoInputType) -> Void)?
    var onConfirm: ((Story) -> Void)?
    var onClose: (() -> Void)?
    
    private let realmDataProvider = RealmDataProvider.shared
    
    init(location: Location) {
        self.location = location
    }
    
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
    
    func showAreYouSureAlert() {
        let alert = AlertConfig(
            title: LocalizationKit.addStory.closeDialogueTitle,
            message: LocalizationKit.addStory.closeDialogueMessage,
            style: .actionSheet,
            actions: [
                AlertAction(
                    title: LocalizationKit.general.close,
                    style: .destructive,
                    handler: { [weak self] in
                        self?.onClose?()
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
    
    func capturePhoto() {
        onShowImagePicker?(.camera)
    }
    
	func confirm() {
        guard var title = title, let image = image else {
			logger.warning("AddVM: confirm failed: title or image is missing")
            return
        }
        
        if title.isEmpty {
            if let n = realmDataProvider?.count(type: Story.self) {
                title = "Story \(n)"
            } else {
                title = "Story"
            }
        }
        #if targetEnvironment(simulator)
        let story = Story(
            title: title,
            image: image,
            location: Configuration.isSimulator
				? location.randomize()
				: location
        )
        #else
        let story = Story(
            title: title,
            image: image,
            location: location
        )
        #endif
        
        realmDataProvider?.write(object: story)
        onConfirm?(story)
    }
    
    func close() {
        showAreYouSureAlert()
    }
}

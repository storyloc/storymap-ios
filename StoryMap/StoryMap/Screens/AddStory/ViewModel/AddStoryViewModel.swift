//
//  AddStoryViewModel.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import Combine

final class AddStoryViewModel {
    let titlePlaceholder: String = LocalizationKit.addStory.titlePlaceholder
    let confirmTitle: String = LocalizationKit.addStory.confirmButtonTitle

	@Published var image: Data?
	
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
    
	let showAlertSubject = PassthroughSubject<AlertConfig, Never>()
	let addImageSubject = PassthroughSubject<PhotoInputManager.SourceType, Never>()
    let confirmSubject = PassthroughSubject<Story, Never>()
	let closeSubject = PassthroughSubject<Void, Never>()
	
	var location: Location
	
	private let storyDataProvider = StoryDataProvider.shared
	
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
						self?.addImageSubject.send(.camera)
                    }
                ),
                AlertAction(
                    title: LocalizationKit.addStory.addPhotoChooseAction,
                    style: .default,
                    handler: { [weak self] in
						self?.addImageSubject.send(.photoLibrary)
                    }
                ),
                AlertAction(
                    title: LocalizationKit.general.cancel,
                    style: .cancel,
                    handler: nil
                )
            ]
        )
        
		showAlertSubject.send(alert)
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
						self?.closeSubject.send()
                    }
                ),
                AlertAction(
                    title: LocalizationKit.general.cancel,
                    style: .cancel,
                    handler: nil
                )
            ]
        )
        
		showAlertSubject.send(alert)
    }
    
    func capturePhoto() {
		addImageSubject.send(.camera)
    }
    
	func confirm() {
        guard var title = title, let image = image else {
			logger.warning("AddVM: confirm failed: title or image is missing")
            return
        }
        
        if title.isEmpty {
			title = "Story \(storyDataProvider.stories.count)"
        }
		
		let story = Story(
			title: title,
			image: image,
			location: Configuration.isSimulator
				? location.randomize()
				: Location(
					latitude: location.latitude,
					longitude: location.longitude
				)
		)
		
		storyDataProvider.save(story: story)
		confirmSubject.send(story)
    }
    
    func close() {
        showAreYouSureAlert()
    }
}

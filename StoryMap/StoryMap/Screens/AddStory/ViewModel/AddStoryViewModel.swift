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
	
    var title: String? = ""
    
    var titleError: String {
        get {
            title?.isEmpty ?? true ? LocalizationKit.addStory.titleError : " "
        }
    }
	
    var confirmButtonEnabled: Bool {
        get {
            !(title?.isEmpty ?? true)
        }
    }
    
	let showAlertSubject = PassthroughSubject<AlertConfig, Never>()
    let confirmSubject = PassthroughSubject<Story, Never>()
	let closeSubject = PassthroughSubject<Void, Never>()

	private let storyDataProvider = StoryDataProvider.shared
    
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

	func confirm() {
        guard var title = title else {
			logger.warning("AddVM: confirm failed: title is missing")
            return
        }
        
        if title.isEmpty {
			title = "Story \(storyDataProvider.stories.count)"
        }
		
		let story = Story(
			title: title,
			collection: []
		)
		
		storyDataProvider.save(story: story)
		confirmSubject.send(story)
    }
    
    func close() {
        showAreYouSureAlert()
    }
}

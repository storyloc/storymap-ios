//
//  StoryDetailViewModel.swift
//  StoryMap
//
//  Created by Dory on 11/01/2022.
//

import Combine
import Foundation

final class StoryDetailViewModel {
	
	// MARK: - Public properties
	
	@Published var storyPointViewModels: [StoryPointDetailViewModel] = []
	
	lazy var title: String = story.title
	
	let closeSubject = PassthroughSubject<Void, Never>()
	let showAlertSubject = PassthroughSubject<AlertConfig, Never>()
	let addStoryPointSubject = PassthroughSubject<PhotoInputManager.SourceType, Never>()
	let storyPointAddedSubject = PassthroughSubject<Void, Never>()
	
	// MARK: - Private properties
	
	private var story: Story
	
	private let storyDataProvider = StoryDataProvider.shared
		
	private var subscriptions = Set<AnyCancellable>()
	
	// MARK: - Initializer
	
	init(story: Story) {
		self.story = story
		
		setupStoryPointViewModels()
		
		NotificationCenter.default.publisher(for: .storyPointCreated, object: nil)
			.sink { [weak self] _ in
				self?.setupStoryPointViewModels()
				self?.storyPointAddedSubject.send()
			}
			.store(in: &subscriptions)
	}
	
	// MARK: - Public methods
	
	func addStoryPoint() {
		showPhotoAlert()
	}
	
	func deleteStory() {
		showAreYouSureAlert()
	}
	
	// MARK: - Private methods
	
	private func setupStoryPointViewModels() {
		storyPointViewModels = story.collection.map { point in
			StoryPointDetailViewModel(storyPoint: point)
		}
	}
	
	private func showAreYouSureAlert() {
		let alert = AlertConfig(
			title: LocalizationKit.storyDetail.deleteAlertTitle,
			message: nil,
			style: .actionSheet,
			actions: [
				AlertAction(
					title: LocalizationKit.storyDetail.deleteAlertAction,
					style: .destructive,
					handler: { [weak self] in
						guard let self = self else { return }
						
						self.storyDataProvider.delete(story: self.story)
						self.closeSubject.send()
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
						self?.addStoryPointSubject.send(.camera)
					}
				),
				AlertAction(
					title: LocalizationKit.addStory.addPhotoChooseAction,
					style: .default,
					handler: { [weak self] in
						self?.addStoryPointSubject.send(.photoLibrary)
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
}

//
//  AddStoryCoordinator.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit
import PhotosUI

final class AddStoryCoordinator: CoordinatorType {
    var presenter = UINavigationController()
    
    var onDidStop: (() -> Void)?
    var onShowStory: ((Story) -> Void)?
    
    private var location: Location
    private var useSimplifiedView = true
    
    init(location: Location, simple: Bool = true) {
        self.location = location
        self.useSimplifiedView = simple
    }
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = AddStoryViewModel(location: location)
        let viewController = makeViewController(with: viewModel, simplified: useSimplifiedView)
        
        viewModel.onShowAlert = { [weak self] alert in
            self?.presenter.present(alert.controller, animated: true)
        }
        viewModel.onClose = { [weak self] in
            self?.stop()
        }
        viewModel.onShowImagePicker = { [weak self] type in
            guard let self = self else { return }
            
            switch type {
            case .camera: self.presenter.visibleViewController?.present(
                self.makePhotoCaptureController(with: viewController),
                animated: true,
                completion: nil
            )
            case .photoLibrary: self.showChooseImageController(with: viewController)
            }
        }
        viewModel.onConfirm = { [weak self] story in
            guard let self = self else { return }
            self.useSimplifiedView ? self.stop() : self.stop(story: story)
        }
        
        presenter.viewControllers = [viewController]
		presenter.modalPresentationStyle = useSimplifiedView ? .fullScreen : .automatic
        presentFrom?.present(presenter, animated: true)
    }
    
    func stop() {
        presenter.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func showChooseImageController(with delegate: PHPickerViewControllerDelegate) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.presenter.visibleViewController?.present(
                        self.makeChooseImageController(with: delegate),
                        animated: true,
                        completion: nil
                    )
                default:
                    let alert = self.makeMissingPermissionsAlert()
                    self.presenter.visibleViewController?.present(alert.controller, animated: true)
                }
            }
        }
    }
    
    func stop(story: Story?) {
        presenter.visibleViewController?.dismiss(animated: true, completion: { [weak self] in
            if let story = story {
                self?.onShowStory?(story)
            }
        })
    }
    
    private func makeChooseImageController(with delegate: PHPickerViewControllerDelegate) -> UIViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = delegate
        return picker
    }
    
    private func makePhotoCaptureController(with delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> UIViewController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = delegate
        return imagePicker
    }
    
    private func makeViewController(with viewModel: AddStoryViewModelType, simplified: Bool) -> AddStoryViewControllerType {
        var viewController: AddStoryViewControllerType
        
        if simplified {
            viewController = AddStorySimplifiedViewController(viewModel: viewModel)
			viewController.addChild(makePhotoCaptureController(with: viewController))
        } else {
            viewController = AddStoryViewController(viewModel: viewModel)
            viewController.isModalInPresentation = true
        }
		
        return viewController
    }
    
    private func makeMissingPermissionsAlert() -> AlertConfig {
        return AlertConfig(
            title: LocalizationKit.addStory.missingPermissionsTitle,
            message: LocalizationKit.addStory.missingPermissionsMessage,
            style: .alert,
            actions: [
                AlertAction(
                    title: LocalizationKit.general.ok,
                    style: .cancel,
                    handler: nil
                )
            ]
        )
    }
}

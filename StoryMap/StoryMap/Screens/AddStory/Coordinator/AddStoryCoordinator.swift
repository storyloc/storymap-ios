//
//  AddStoryCoordinator.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit
import PhotosUI

class AddStoryCoordinator: CoordinatorType {

    var presenter = UINavigationController()
    
    var onDidStop: (() -> Void)?
    
    func start(_ presentFrom: UIViewController?) {
        let viewModel = AddStoryViewModel()
        viewModel.onShowAlert = { [weak self] alert in
            self?.presenter.present(alert.controller, animated: true)
        }
        
        let viewController = AddStoryViewController(viewModel: viewModel)
        viewModel.onShowImagePicker = { [weak self] type in
            guard let self = self else { return }
            
            switch type {
            case .camera: self.presenter.visibleViewController?.present(
                self.makePhotoCaptureController(with: viewController),
                animated: true,
                completion: nil
            )
            case .photoLibrary:
                self.presenter.visibleViewController?.present(
                    self.makeChooseImageController(with: viewController),
                    animated: true,
                    completion: nil
                )
            }
        }
        presenter.viewControllers = [viewController]
        presentFrom?.present(presenter, animated: true)
    }
    
    func stop() {
        
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
        imagePicker.delegate = delegate
        return imagePicker
    }
}

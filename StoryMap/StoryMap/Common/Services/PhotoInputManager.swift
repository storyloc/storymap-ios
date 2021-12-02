//
//  PhotoInputManager.swift
//  StoryMap
//
//  Created by Dory on 02/12/2021.
//

import UIKit
import PhotosUI
import Combine

final class PhotoInputManager: NSObject {
	public enum SourceType {
		case camera
		case photoLibrary
	}
	
	// MARK: - Public properties
	
	var imageSubject = PassthroughSubject<UIImage, Never>()
	
	// MARK: - Public methods
	
	public func makeViewController(with sourceType: SourceType) -> UIViewController {
		sourceType == .camera ? makePhotoCaptureController() : makeChooseImageController()
	}
	
	// MARK: - Private methods
	
	private func makeChooseImageController() -> UIViewController {
		var config = PHPickerConfiguration()
		config.filter = .images
		config.selectionLimit = 1
		let picker = PHPickerViewController(configuration: config)
		picker.delegate = self
		return picker
	}
	
	private func makePhotoCaptureController() -> UIViewController {
		let imagePicker = UIImagePickerController()
		imagePicker.sourceType = .camera
		imagePicker.delegate = self
		return imagePicker
	}
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoInputManager: PHPickerViewControllerDelegate {
	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
		guard let result = results.first else { return }
		let provider = result.itemProvider
		
		provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
			if let pickedImage = image as? UIImage {
				self?.imageSubject.send(pickedImage)
			}
		}
	}
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension PhotoInputManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let pickedImage = info[.originalImage] as? UIImage {
			imageSubject.send(pickedImage)
		}
	}
}
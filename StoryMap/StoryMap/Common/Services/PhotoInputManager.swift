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
	public typealias Result = (image: UIImage, location: Location?)
	
	public enum SourceType {
		case camera
		case photoLibrary
	}
	
	// MARK: - Public properties
	
	var resultSubject = PassthroughSubject<Result, Never>()
	var cancelSubject = PassthroughSubject<Void, Never>()
	
	// MARK: - Public methods
	
	public func makeViewController(with sourceType: SourceType) -> UIViewController {
		sourceType == .camera ? makePhotoCaptureController() : makeChooseImageController()
	}
	
	// MARK: - Private methods
	
	private func makeChooseImageController() -> UIViewController {
		let photoLibrary = PHPhotoLibrary.shared()
		var config = PHPickerConfiguration(photoLibrary: photoLibrary)
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
		guard let result = results.first else {
			cancelSubject.send()
			return
		}
		
		var location: Location?
		
		if let identifier = result.assetIdentifier {
			if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject, let loc = asset.location {
				location = Location(location: loc)
			}
		} else {
			logger.warning("PhotoManager: getLocationFromAsset failed: missing identifier")
		}
		
		let provider = result.itemProvider
		
		provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
			if let pickedImage = image as? UIImage {
				self?.resultSubject.send(Result(image: pickedImage, location: location))
			}
		}
	}
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension PhotoInputManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let pickedImage = info[.originalImage] as? UIImage {
			if !Configuration.isDebug {
				UIImageWriteToSavedPhotosAlbum(pickedImage, nil, nil, nil)
			}
			
			resultSubject.send(Result(image: pickedImage, location: nil))
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		cancelSubject.send()
	}
}

//
//  AddStorySimplifiedViewController.swift
//  StoryMap
//
//  Created by Dory on 12/11/2021.
//

import Foundation
import UIKit
import PhotosUI

class AddStorySimplifiedViewController: UIViewController, AddStoryViewControllerType {
    
    private var viewModel: AddStoryViewModelType
    
    init(viewModel: AddStoryViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.capturePhoto()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension AddStorySimplifiedViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        dismiss(animated: false) { [weak self] in
            self?.viewModel.image = image.jpegData(compressionQuality: 1)
            self?.viewModel.confirm()
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
    }
}

//
//  AddStorySimplifiedViewController.swift
//  StoryMap
//
//  Created by Dory on 12/11/2021.
//

import Foundation
import UIKit
import PhotosUI

final class AddStorySimplifiedViewController: UIViewController, AddStoryViewControllerType {
    
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
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
	
	override func addChild(_ viewController: UIViewController) {
		super.addChild(viewController)
		view.addSubview(viewController.view)
		
		viewController.view.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}
}

// MARK: - UIImagePickerControllerDelegate

extension AddStorySimplifiedViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		guard let image = info[.originalImage] as? UIImage else {
			logger.warning("AddVC: captured image not converted")
            return
        }
		
		viewModel.image = image.jpegData(compressionQuality: 0.5)
		viewModel.confirm()
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {}
}

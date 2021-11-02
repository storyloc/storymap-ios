//
//  MapViewController.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import Foundation
import UIKit

class MapViewController: UIViewController {
    
    // MARK: - Constants
    
    var onAddStory: (() -> Void)?
    
    private let addButton = UIButton(type: .system)
    
    private let buttonOffset: CGFloat = 44
    private let buttonSize: CGFloat = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupButton()
    }
    
    private func setupButton() {
        addButton.setImage(
            StyleKit.image.make(
                from: StyleKit.image.icons.plus,
                with: .alwaysTemplate
            ),
            for: .normal
        )
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        view.addSubview(addButton)
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -buttonOffset),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -buttonOffset),
            addButton.widthAnchor.constraint(equalToConstant: buttonSize),
            addButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }
    
    @objc private func addButtonTapped() {
        onAddStory?()
    }
}

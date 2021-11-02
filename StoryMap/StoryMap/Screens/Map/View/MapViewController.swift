//
//  MapViewController.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import Foundation
import UIKit

class MapViewController: UIViewController {
    
    // MARK: - Variables
    
    private var viewModel: MapViewModelType
    
    // MARK: - Constants
    
    private let addButton = UIButton(type: .system)
    
    // MARK: - Initializers
    
    init(viewModel: MapViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        view.backgroundColor = .white
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
        
        addButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(StyleKit.metrics.padding.medium)
            make.trailing.equalToSuperview().inset(StyleKit.metrics.padding.large)
            make.width.height.equalTo(StyleKit.metrics.buttonHeight)
        }
    }
    
    @objc private func addButtonTapped() {
        viewModel.addStory()
    }
}

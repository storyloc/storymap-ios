//
//  StoryDetailViewController.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import UIKit

class StoryDetailViewController: UIViewController {
    private var viewModel: StoryDetailViewModelType

    private let imageView = UIImageView()
    
    init(viewModel: StoryDetailViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = viewModel.story.title
        view.backgroundColor = .white
        setupImageView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(data: viewModel.story.image)
        
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.verySmall)
            make.width.height.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.width)
            make.centerX.equalToSuperview()
        }
    }
}

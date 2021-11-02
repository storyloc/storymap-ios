//
//  StoryDetailViewController.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import UIKit

class StoryDetailViewController: UIViewController {
    var viewModel: StoryDetailViewModelType
    
    init(viewModel: StoryDetailViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = "Story"
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

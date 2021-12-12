//
//  SceneDelegate.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var mapCoordinator: CoordinatorType?
    var listCoordinator: CoordinatorType?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
			let navigationController = UINavigationController()
			self.mapCoordinator = MapCoordinator(presenter: navigationController)
            self.listCoordinator = StoryListCoordinator(presenter: navigationController)
            
            self.window = UIWindow(windowScene: windowScene)
        
            self.window?.rootViewController = mapCoordinator?.presenter
            self.window?.backgroundColor = .black
            self.window?.makeKeyAndVisible()
            listCoordinator?.start()
//            mapCoordinator?.start()
        }
    }
}


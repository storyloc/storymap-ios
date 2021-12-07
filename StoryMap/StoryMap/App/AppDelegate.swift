//
//  AppDelegate.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import UIKit
import OSLog
import Apollo

public let logger = Logger()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		if Configuration.isDebug {
			tryGraphQL()
		}
		
		return true
    }
	
	private func tryGraphQL() {
		Network.shared.apollo.perform(mutation: CreateProfileMutation(name: "Dory")) { result in
			switch result {
			case .success(let graphQLResult):
				logger.info("Success! Result: \(String(describing: graphQLResult.data?.createProfile))")
			case .failure(let error):
				logger.warning("Failure! Error: \(error.localizedDescription)")
			}
		}
	}
}


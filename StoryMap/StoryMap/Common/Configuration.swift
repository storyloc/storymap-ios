//
//  Configuration.swift
//  StoryMap
//
//  Created by Dory on 30/11/2021.
//

import Foundation

struct Configuration {
	static var isSimulator: Bool {
		#if targetEnvironment(simulator)
		return true
		#else
		return false
		#endif
	}
	
	static var isDebug: Bool {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}
}

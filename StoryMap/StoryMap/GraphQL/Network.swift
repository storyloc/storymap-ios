//
//  Network.swift
//  StoryMap
//
//  Created by Dory on 07/12/2021.
//

import Foundation
import Apollo

class Network {
  static let shared = Network()
	
	private(set) lazy var apollo = ApolloClient(url: Configuration.serverURL)
}

//
//  String+Localized.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation

public extension String {
    var localized: String {
        get {
            NSLocalizedString(self, comment: "")
        }
    }
}

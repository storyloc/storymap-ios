//
//  Metrics.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

/// Definition of paddings, radii and other constants used in app layout.
struct Metrics {
    let padding = Padding()
    let cornerRadius: CGFloat = 8
    let separator: CGFloat = 1
    let buttonHeight: CGFloat = 44
    let tableRowHeight: CGFloat = 56
    let textFieldHeight: CGFloat = 40
    let imageWidth: CGFloat = 200

    struct Padding {
        let common: CGFloat = 20
        let verySmall: CGFloat = 5
        let small: CGFloat = 10
        let medium: CGFloat = 30
        let large: CGFloat = 50
    }
}

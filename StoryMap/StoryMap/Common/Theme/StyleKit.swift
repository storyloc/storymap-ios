//
//  StyleKit.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

/// Structure holding all necessary information about app design.
/// - All the UI Constants used through the app should be stored here to avoid ambiguity in code.
struct StyleKit {
    static let font = FontKit()
    static let metrics = Metrics()
    static let image = ImageKit()

    static func styleTextField(_ textField: inout UITextField) {
        textField.borderStyle = .roundedRect
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = StyleKit.metrics.separator
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = StyleKit.metrics.cornerRadius
        textField.backgroundColor = .white
        textField.tintColor = .lightGray
        textField.textColor = .systemBlue
        textField.returnKeyType = .next
    }
}

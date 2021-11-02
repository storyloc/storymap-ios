//
//  ImageKit.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

struct ImageKit {
    let icons = Icons()
}

extension ImageKit {
    struct Icons {
        let plus = "ic-plus"
        let record = "ic-record"
    }
}

extension ImageKit {
    func make(from name: String, with renderingMode: UIImage.RenderingMode = .alwaysOriginal) -> UIImage? {
        UIImage(named: name)?.withRenderingMode(renderingMode)
    }
}

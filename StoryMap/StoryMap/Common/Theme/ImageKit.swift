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
    let examples = Examples()
}

extension ImageKit {
    struct Icons {
        let plus = "ic-plus"
        let centerOn = "ic-center-on"
        let centerOff = "ic-center-off"
        let record = "ic-record"
        let delete = "ic-delete"
        let play = "ic-play"
        let pause = "ic-pause"
        let list = "ic-list"
    }
    
    struct Examples {
        let waterfall = "ex-waterfall"
        let mountain = "ex-mountain"
        
        func random() -> String {
            return [waterfall, mountain].randomElement()!
        }
    }
}

extension ImageKit {
    func make(from name: String, with renderingMode: UIImage.RenderingMode = .alwaysOriginal) -> UIImage? {
        UIImage(named: name)?.withRenderingMode(renderingMode)
    }
}

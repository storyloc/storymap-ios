//
//  FontKit.swift
//  StoryMap
//
//  Created by Dory on 21/10/2021.
//

import Foundation
import UIKit

/// Definition of fonts used in the application.
struct FontKit {
    var title1: UIFont { UIFont.preferredFont(forTextStyle: .title1) } // 28
    var title2: UIFont { UIFont.preferredFont(forTextStyle: .title2) } // 22
    var title3: UIFont { UIFont.preferredFont(forTextStyle: .title3) } // 20
    var body: UIFont { UIFont.preferredFont(forTextStyle: .body) } // 17
    var callout: UIFont { UIFont.preferredFont(forTextStyle: .callout) } // 16
    var subhead: UIFont { UIFont.preferredFont(forTextStyle: .subheadline) } // 15
    var caption1: UIFont { UIFont.preferredFont(forTextStyle: .caption1) } // 13
    var caption2: UIFont { UIFont.preferredFont(forTextStyle: .caption2) } // 12
    var footnote: UIFont { UIFont.preferredFont(forTextStyle: .footnote) } // 11
}

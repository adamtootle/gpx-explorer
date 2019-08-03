//
//  HighlightButton.swift
//  GPX
//
//  Created by Adam Tootle on 8/3/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit

class HighlightButton: UIButton {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0) : UIColor.white
        }
    }
}

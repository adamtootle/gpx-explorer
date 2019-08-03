//
//  CollectionViewLabelCell.swift
//  GPX
//
//  Created by Adam Tootle on 8/3/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit

class CollectionViewLabelCell: UICollectionViewCell {
    @IBOutlet var label: UILabel!
    var text: String? {
        didSet {
            self.label.text = text
        }
    }
}

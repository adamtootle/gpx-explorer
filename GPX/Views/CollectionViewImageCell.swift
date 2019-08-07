//
//  CollectionViewImageCell.swift
//  GPX
//
//  Created by Adam Tootle on 8/3/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit

class CollectionViewImageCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }
}

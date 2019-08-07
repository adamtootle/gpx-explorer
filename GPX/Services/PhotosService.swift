//
//  PhotosService.swift
//  GPX
//
//  Created by Adam Tootle on 8/4/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit
import Photos

class PhotosService {
    static func loadPhotos(startDate: Date, endDate: Date, completionHandler: @escaping ([(image: UIImage, asset: PHAsset)]) -> Void) {
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        //        requestOptions.synchronous = true
        //        requestOptions.networkAccessAllowed = true
        
        // Fetch the images between the start and end date
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@ AND creationDate < %@", startDate as CVarArg, endDate as CVarArg)
        
        var images: [(image: UIImage, asset: PHAsset)] = []
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        if fetchResult.count == 0 {
            completionHandler([])
            return
        }
        
        var accountedFor = 0
        for index in 0..<fetchResult.count {
            let asset = fetchResult.object(at: index)
            
            imgManager.requestImageData(for: asset, options: requestOptions) { (imageData, dataUTI, orientation, info) in
                accountedFor += 1
                
                if let imageData = imageData {
                    if let image = UIImage(data: imageData) {
                        images.append((image: image, asset: asset))
                    }
                }
                
                if accountedFor == fetchResult.count {
                    completionHandler(images)
                }
            }
        }
    }
}

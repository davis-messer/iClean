//
//  PhotoItem.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  Model for one loaded sorting card: the displayed image, its source
//  library asset, and the mutable offset/rotation state driven by swipes.
//

import UIKit
import Photos

/// A loaded sorting-card image, its optional library asset, and mutable presentation state.
struct PhotoItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let asset: PHAsset?
    var offset: CGSize = .zero
    var degrees: Double = 0
    var zIndex: Double = 0

    /// Creates a centered, unrotated card, optionally linked to an asset for later deletion.
    init(image: UIImage, asset: PHAsset? = nil) {
        self.image = image
        self.asset = asset
    }
}


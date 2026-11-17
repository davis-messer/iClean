//
//  DuplicateGroup.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  Model for one group of library assets believed to be duplicates of each
//  other, as produced by the duplicate scan and shown in the Duplicates tab.
//

import Foundation
import Photos

/// Assets grouped by matching sampled-thumbnail hashes, with a stable identity for the results UI.
struct DuplicateGroup: Identifiable {
    let id = UUID()
    var assets: [PHAsset]
}


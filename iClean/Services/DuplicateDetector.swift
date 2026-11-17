//
//  DuplicateDetector.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  Pure duplicate-detection heuristics: a cheap metadata key for bucketing
//  candidate assets, and a sampled-pixel hash for comparing thumbnails.
//  Free of image-loading side effects so it can be unit-tested in isolation.
//

import CoreGraphics
import Photos

/// Lightweight candidate keys and sampled-image hashes, independent of image-loading requests.
/// Matching hashes are a heuristic, not proof that two full-resolution images are identical.
enum DuplicateDetector {

    /// Coarse first-pass key used to bucket candidate duplicates cheaply.
    /// Lenient on purpose — dimensions only — so the expensive pixel compare
    /// only runs on same-size assets.
    static func metadataKey(for asset: PHAsset) -> String {
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        return "\(width)x\(height)"
    }

    /// Builds a string from one byte at each of 16 diagonal sample positions.
    /// Returns a unique fallback when pixel data is unavailable to avoid grouping unreadable images.
    static func hash(from cgImage: CGImage) -> String {
        let width = cgImage.width
        let height = cgImage.height

        // Sample a few pixels to create a hash
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return UUID().uuidString
        }

        // Sample 16 points across the image
        var hash = ""
        let samplePoints = 16
        let bytesPerPixel = cgImage.bitsPerPixel / 8

        for i in 0..<samplePoints {
            let x = (width * i) / samplePoints
            let y = (height * i) / samplePoints
            let offset = (y * width + x) * bytesPerPixel

            if offset < CFDataGetLength(data) {
                hash += String(format: "%02x", bytes[offset])
            }
        }

        return hash
    }
}


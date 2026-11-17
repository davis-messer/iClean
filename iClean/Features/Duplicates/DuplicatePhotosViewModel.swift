//
//  DuplicatePhotosViewModel.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  State and scan pipeline for the Duplicates screen: buckets assets by
//  metadata, verifies candidates via thumbnail hashes in batches, and
//  handles deletion of selected photos from the results.
//

import SwiftUI
import Photos
import Combine

/// Scans same-dimension assets for matching thumbnail hashes and manages deletion from results.
class DuplicatePhotosViewModel: ObservableObject {
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var hasScanned = false
    @Published var scannedCount = 0
    @Published var showError = false
    @Published var errorMessage = ""

    private let library = PhotoLibraryService()

    /// Counts removable copies if one asset is retained from each displayed group.
    var totalDuplicates: Int {
        duplicateGroups.reduce(0) { $0 + $1.assets.count - 1 }
    }

    /// Resets results, buckets accessible assets on a background queue, then compares candidates.
    func scanForDuplicates() {
        isScanning = true
        hasScanned = false
        scannedCount = 0
        duplicateGroups = []

        DispatchQueue.global(qos: .userInitiated).async {
            let assets = self.library.fetchImageAssets(sortedByCreationDate: true)

            // First pass: bucket by pixel width and height without loading image data.
            var metadataGroups: [String: [PHAsset]] = [:]

            for asset in assets {
                let key = DuplicateDetector.metadataKey(for: asset)

                if metadataGroups[key] != nil {
                    metadataGroups[key]?.append(asset)
                } else {
                    metadataGroups[key] = [asset]
                }

                DispatchQueue.main.async {
                    self.scannedCount += 1
                }
            }

            // Second pass: Verify potential duplicates asynchronously
            let potentialDuplicates = metadataGroups.filter { $0.value.count > 1 }

            if potentialDuplicates.isEmpty {
                DispatchQueue.main.async {
                    self.duplicateGroups = []
                    self.isScanning = false
                    self.hasScanned = true
                }
                return
            }

            self.verifyDuplicatesAsync(groups: Array(potentialDuplicates.values))
        }
    }

    /// Compares up to ten candidate groups at a time, then publishes largest groups first.
    /// Waits between batches, so this method must run off the main queue.
    private func verifyDuplicatesAsync(groups: [[PHAsset]]) {
        var confirmedDuplicates: [DuplicateGroup] = []
        let manager = PHImageManager.default()
        let dispatchGroup = DispatchGroup()
        let lock = NSLock()

        // Process in batches to avoid memory issues
        let batchSize = 10
        let batches = stride(from: 0, to: groups.count, by: batchSize).map {
            Array(groups[$0..<min($0 + batchSize, groups.count)])
        }

        for batch in batches {
            for assets in batch {
                dispatchGroup.enter()

                // Process each group of potential duplicates
                self.compareAssets(assets, manager: manager) { duplicateGroup in
                    if let group = duplicateGroup {
                        lock.lock()
                        confirmedDuplicates.append(group)
                        lock.unlock()
                    }
                    dispatchGroup.leave()
                }
            }

            // Wait for batch to complete before starting next batch
            dispatchGroup.wait()
        }

        // Sort and update UI
        confirmedDuplicates.sort { $0.assets.count > $1.assets.count }

        DispatchQueue.main.async {
            self.duplicateGroups = confirmedDuplicates
            self.isScanning = false
            self.hasScanned = true
        }
    }

    /// Hashes locally available 50pt thumbnails and returns only the largest matching subset.
    /// Assets without a usable local image are skipped; iCloud downloads are disabled.
    private func compareAssets(_ assets: [PHAsset], manager: PHImageManager, completion: @escaping (DuplicateGroup?) -> Void) {
        var assetHashes: [String: [PHAsset]] = [:]
        let group = DispatchGroup()
        let lock = NSLock()

        for asset in assets {
            group.enter()

            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            options.deliveryMode = .fastFormat

            // Use tiny thumbnail to create hash - much more memory efficient
            let targetSize = CGSize(width: 50, height: 50)
            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                defer { group.leave() }

                guard let image = image,
                      let cgImage = image.cgImage else { return }

                // Create a simple hash from pixel data
                let hash = DuplicateDetector.hash(from: cgImage)

                lock.lock()
                if assetHashes[hash] != nil {
                    assetHashes[hash]?.append(asset)
                } else {
                    assetHashes[hash] = [asset]
                }
                lock.unlock()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            // Find the largest group of duplicates
            if let largestGroup = assetHashes.values.max(by: { $0.count < $1.count }),
               largestGroup.count > 1 {
                completion(DuplicateGroup(assets: largestGroup))
            } else {
                completion(nil)
            }
        }
    }

    /// Deletes selected assets, then updates or removes their result group on success.
    /// Publishes an error without changing the group when the PhotoKit transaction fails.
    func deletePhotos(assets: [PHAsset], from group: DuplicateGroup) {
        library.deleteAssets(assets) { success, error in
            DispatchQueue.main.async {
                if success {
                    // Remove deleted assets from the group
                    if let index = self.duplicateGroups.firstIndex(where: { $0.id == group.id }) {
                        let remainingAssets = self.duplicateGroups[index].assets.filter { asset in
                            !assets.contains(where: { $0.localIdentifier == asset.localIdentifier })
                        }

                        if remainingAssets.count > 1 {
                            self.duplicateGroups[index].assets = remainingAssets
                        } else {
                            self.duplicateGroups.remove(at: index)
                        }
                    }
                } else {
                    self.errorMessage = "Failed to delete photos: \(error?.localizedDescription ?? "Unknown error")"
                    self.showError = true
                }
            }
        }
    }
}


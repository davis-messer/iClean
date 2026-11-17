//  PhotoLibraryService.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
///  The app's single gateway to PhotoKit library operations: requesting
///  authorization, fetching all image assets, and batch-deleting assets.
///  Both feature view models depend on this instead of calling PhotoKit directly.

import Photos

/// Centralizes the PhotoKit operations shared by the view models:
/// authorization, fetching image assets, and deleting assets.
///
/// Callback-based to mirror PhotoKit's own API; the view models remain
/// responsible for hopping back to the main actor.
struct PhotoLibraryService {

    /// Requests read/write access; callers decide how to handle limited or denied authorization.
    func requestAuthorization(_ completion: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: completion)
    }

    /// Fetches every image asset in the library.
    /// - Parameter sortedByCreationDate: when true, newest first; otherwise
    ///   the library's default order (callers may shuffle).
    func fetchImageAssets(sortedByCreationDate: Bool = false) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        if sortedByCreationDate {
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Submits one PhotoKit deletion transaction and forwards its success or error callback.
    func deleteAssets(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }, completionHandler: completion)
    }
}


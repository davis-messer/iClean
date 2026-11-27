//  SortingViewModel.swift
//  iClean
//
//  State machine for the Sort screen: library authorization and loading,
//  the cursor-based sliding window of loaded cards, swipe gesture handling,
//  and the deferred batch-deletion queue.

import SwiftUI
import Photos
import Combine

/// Manages library access, a small loaded-card window, swipe state, and deferred batch deletion.
class SortingViewModel: ObservableObject {
    @Published var images: [PhotoItem] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    /// Assets the user has swiped to delete but not yet committed. The actual
    /// library deletion is deferred until `commitDeletions()` so the user gets
    /// a single system confirmation instead of one per photo.
    @Published var pendingDeletions: [PHAsset] = []
    /// False until the user picks a starting photo from the library grid;
    /// the view shows the picker while this is false and the card stack after.
    @Published var hasStartedSorting = false

    /// The full list of assets, newest first. Immutable after `loadPhotos()`;
    /// progress through it is tracked solely by `cursor`, never by mutating this array.
    /// Also drives the starting-photo picker grid.
    @Published private(set) var libraryAssets: [PHAsset] = []
    /// Index of the next asset to load into the display window — the single
    /// source of truth for how far we've advanced through `libraryAssets`.
    private var cursor = 0
    /// Guards against issuing overlapping image requests while one is in flight.
    private var isFilling = false
    private let library = PhotoLibraryService()
    private let imageManager = PHImageManager.default()
    private let preloadCount = 5 // Only keep 5 images in memory

    /// Loads accessible assets after authorization, or publishes an error if access is denied.
    func requestPhotoLibraryAccess() {
        library.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self.loadPhotos()
                } else {
                    self.errorMessage = "Photo library access is required. Please enable it in Settings."
                    self.showError = true
                }
            }
        }
    }

    /// Fetches newest-first asset metadata off the main queue and resets the starting-photo picker.
    private func loadPhotos() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let assets = self.library.fetchImageAssets(sortedByCreationDate: true)

            DispatchQueue.main.async {
                self.libraryAssets = assets
                self.cursor = 0
                self.images = []
                self.hasStartedSorting = false
                self.isLoading = false
            }
        }
    }

    /// Begins the swipe flow at the chosen photo, then proceeds sequentially
    /// through the library (newest first) from that point.
    func startSorting(from asset: PHAsset) {
        guard let index = libraryAssets.firstIndex(of: asset) else { return }
        cursor = index
        images = []
        hasStartedSorting = true
        fillWindow()
    }

    /// Loads assets starting at `cursor` until the display window holds
    /// `preloadCount` items (or the library is exhausted). Loads one at a time,
    /// in order, so the stack stays in a stable sequence and no asset is ever
    /// skipped or loaded twice: `cursor` advances by exactly one per asset.
    private func fillWindow() {
        guard !isFilling else { return }
        guard images.count < preloadCount, cursor < libraryAssets.count else { return }

        isFilling = true
        let asset = libraryAssets[cursor]
        cursor += 1

        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.resizeMode = .fast

        // Use screen-appropriate size to reduce memory
        let targetSize = CGSize(width: 800, height: 800)
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self.images.append(PhotoItem(image: image, asset: asset))
                }
                self.isFilling = false
                // Keep topping up until the window is full.
                self.fillWindow()
            }
        }
    }

    /// Updates only the front card's translation and derives its tilt from horizontal drag distance.
    func updatePhotoOffset(id: UUID, value: DragGesture.Value, containerWidth: CGFloat) {
        if let index = images.firstIndex(where: { $0.id == id }), index == 0 {
            images[index].offset = value.translation

            // Calculate rotation based on drag distance using provided container width
            let rotationStrength = min(value.translation.width / max(containerWidth, 1), 1)
            images[index].degrees = Double(rotationStrength * 15)
        }
    }

    /// Commits a keep/delete swipe beyond 100pt, or springs the front card back to its center.
    func handleSwipeEnded(id: UUID, value: DragGesture.Value, containerWidth: CGFloat) {
        guard let index = images.firstIndex(where: { $0.id == id }), index == 0 else { return }

        let threshold: CGFloat = 100
        let swipeDistance = value.translation.width

        if swipeDistance > threshold {
            // Swiped right - keep
            animateSwipeOff(direction: .right)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.swipePhotoRight()
            }
        } else if swipeDistance < -threshold {
            // Swiped left - delete
            animateSwipeOff(direction: .left)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.swipePhotoLeft()
            }
        } else {
            // Return to center
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                images[index].offset = .zero
                images[index].degrees = 0
            }
        }
    }

    /// Animates the front card 500pt sideways before its delayed removal from the stack.
    private func animateSwipeOff(direction: SwipeDirection) {
        guard !images.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let offset: CGFloat = direction == .left ? -500 : 500
            images[0].offset = CGSize(width: offset, height: 0)
            images[0].degrees = direction == .left ? -15 : 15
        }
    }

    /// Maps a completed swipe to the delete (left) or keep (right) exit animation.
    enum SwipeDirection {
        case left, right
    }

    /// Keeps the front photo in the library, removes its card, and replenishes the loaded window.
    func swipePhotoRight() {
        // Keep the photo - just remove from stack
        guard !images.isEmpty else { return }
        _ = images.removeFirst()
        // Top up the window from the master list (libraryAssets is never mutated).
        fillWindow()
    }

    /// Queues the front card's asset for later deletion and replenishes the loaded window.
    func swipePhotoLeft() {
        // Mark the photo for deletion - the actual delete is deferred until
        // the user commits, so it happens as a single batch (one prompt).
        guard !images.isEmpty else { return }
        let photoToDelete = images.first!

        _ = images.removeFirst()

        if let asset = photoToDelete.asset {
            pendingDeletions.append(asset)
        }

        // Top up the window from the master list (libraryAssets is never mutated).
        fillWindow()
    }

    /// Deletes every photo the user has marked for deletion in one batch.
    /// Produces a single system confirmation prompt covering all of them.
    /// On failure (including the user declining the prompt), the pending list
    /// is kept so they can try again.
    func commitDeletions() {
        guard !pendingDeletions.isEmpty else { return }
        let assets = pendingDeletions

        library.deleteAssets(assets) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.pendingDeletions.removeAll()
                    self.loadPhotos() // Update photo library after deletions
                } else {
                    self.errorMessage = "Failed to delete photos: \(error?.localizedDescription ?? "Unknown error")"
                    self.showError = true
                }
            }
        }
    }
}


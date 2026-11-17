//
//  PhotoLibraryView.swift
//  iClean
//
//  Grid of library thumbnails from which the user picks where sorting
//  begins, plus the reusable self-loading asset thumbnail cell.
//

import SwiftUI
import Photos

/// Displays assets in their supplied order in an adaptive grid; tapping one chooses the sorting start.
struct PhotoLibraryView: View {
    let assets: [PHAsset]
    let onSelect: (PHAsset) -> Void

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose a Starting Photo")
                .font(.headline)
                .foregroundColor(AppTheme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .retroPanel()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        Button {
                            onSelect(asset)
                        } label: {
                            AssetThumbnailView(asset: asset)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

/// Loads and displays a small square thumbnail for a single asset.
struct AssetThumbnailView: View {
    let asset: PHAsset

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(AppTheme.cream)
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.ink, lineWidth: 1.5)
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear(perform: loadThumbnail)
        .onDisappear(perform: cancelLoad)
    }

    /// Requests a 200pt thumbnail, allowing iCloud downloads and opportunistic quality updates.
    private func loadThumbnail() {
        guard image == nil else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        let targetSize = CGSize(width: 200, height: 200)
        requestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                image = result
            }
        }
    }

    /// Cancels any outstanding Photos request when this thumbnail leaves the screen.
    private func cancelLoad() {
        if let requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        requestID = nil
    }
}

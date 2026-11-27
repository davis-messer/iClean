//
//  PhotoPreviewView.swift
//  iClean
//
//  Full-screen photo viewer presented as a sheet from a duplicate
//  thumbnail: pinch zoom, panning, double-tap zoom/reset, and asset details.
//

import SwiftUI
import Photos

/// Sheet-based photo viewer with pinch zoom, panning, double-tap reset/zoom, and asset details.
struct PhotoPreviewView: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                Spacer()

                if let fullImage = fullImage {
                    Image(uiImage: fullImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        // Accumulate pinch scale across gestures; reset pan when shrinking below 1×.
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // Reset if zoomed out too much
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        // Accumulate drag translation so successive gestures continue from the last offset.
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        // Double-tap to switch between a centered 1× view and 2× zoom.
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }

                Spacer()

                // Show pixel dimensions and the formatted timestamp when a creation date is available.
                if let creationDate = asset.creationDate {
                    VStack(spacing: 4) {
                        Text("\(asset.pixelWidth) × \(asset.pixelHeight)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(formatDate(creationDate))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            loadFullImage()
        }
    }

    /// Requests the maximum-size preview, allowing PhotoKit to download an iCloud-backed image.
    private func loadFullImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            self.fullImage = image
        }
    }

    /// Formats the asset timestamp using the user's locale with a medium date and short time.
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

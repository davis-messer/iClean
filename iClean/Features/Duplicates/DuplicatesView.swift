//
//  DuplicatesView.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  The Duplicates screen: scan progress, empty/initial states, and the list
//  of duplicate groups. Also contains the thumbnail cell and the zoomable
//  full-screen photo preview sheet.
//

import SwiftUI
import Photos

/// Presents scan progress, initial/empty states, and selectable groups of candidate duplicates.
struct DuplicatePhotosView: View {
    @StateObject private var viewModel = DuplicatePhotosViewModel()

    var body: some View {
        ZStack {
            // Transparent so ContentView's graph-paper background shows through.
            Color.clear

            // Choose the scan-progress, empty-results, or populated-results presentation.
            VStack {
                if viewModel.isScanning {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.ink)
                        Text("Scanning for duplicates...")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.ink)
                        if viewModel.scannedCount > 0 {
                            Text("\(viewModel.scannedCount) photos scanned")
                                .font(.caption)
                                .foregroundColor(AppTheme.ink.opacity(0.6))
                        }
                    }
                    .padding(30)
                    .retroPanel()
                } else if viewModel.duplicateGroups.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: viewModel.hasScanned ? "checkmark.circle.fill" : "photo.stack")
                            .font(.system(size: 80))
                            .foregroundColor(viewModel.hasScanned ? AppTheme.teal : AppTheme.ink.opacity(0.5))
                        Text(viewModel.hasScanned ? "No Duplicates Found" : "Find Duplicate Photos")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.ink)
                        Text(viewModel.hasScanned ? "Your library is clean!" : "Scan your photo library to find duplicate images")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if !viewModel.hasScanned {
                            Button(action: { viewModel.scanForDuplicates() }) {
                                Label("Scan for Duplicates", systemImage: "magnifyingglass")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.ink)
                                    .padding()
                                    .retroPanel(fill: AppTheme.teal, cornerRadius: 12)
                            }
                            .buttonStyle(.plain)
                            .padding(.top)
                        }
                    }
                    .padding(30)
                    .retroPanel()
                    .padding(.horizontal)
                } else {
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                            Text("Found \(viewModel.duplicateGroups.count) Groups")
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.ink)
                            Text("\(viewModel.totalDuplicates) duplicate photos")
                                .font(.caption)
                                .foregroundColor(AppTheme.ink.opacity(0.6))
                        }
                            Spacer()
                            Button(action: { viewModel.scanForDuplicates() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.headline.bold())
                                    .foregroundColor(AppTheme.ink)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.plain)
                            .retroCircle(fill: AppTheme.pickerPink)
                        }
                        .padding()
                        .retroPanel()
                        .padding(.horizontal)

                        // Lazily render result groups and forward their selected deletion requests.
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.duplicateGroups) { group in
                                    DuplicateGroupView(group: group, onDelete: { assets in
                                        viewModel.deletePhotos(assets: assets, from: group)
                                    })
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

/// Selectable 120pt thumbnail; a half-second long press opens the larger photo preview.
struct DuplicatePhotoCell: View {
    let asset: PHAsset
    let isSelected: Bool
    let onTap: () -> Void
    @State private var image: UIImage?
    @State private var showPreview = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.ink)
                            .offset(x: 2.5, y: 3.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? AppTheme.coral : AppTheme.ink, lineWidth: isSelected ? 3 : 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.pickerPink)
                    .frame(width: 120, height: 120)
                    .overlay(ProgressView().tint(AppTheme.ink))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.ink, lineWidth: 2)
                    )
            }

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.coral)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(AppTheme.ink, lineWidth: 1.5))
                    .padding(5)
            }
        }
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.5) {
            showPreview = true
        }
        .sheet(isPresented: $showPreview) {
            PhotoPreviewView(asset: asset)
        }
        .onAppear {
            loadImage()
        }
    }

    /// Requests a high-quality 240pt thumbnail for the cell without enabling iCloud downloads.
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 240, height: 240),
            contentMode: .aspectFill,
            options: options
        ) { img, _ in
            self.image = img
        }
    }
}

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


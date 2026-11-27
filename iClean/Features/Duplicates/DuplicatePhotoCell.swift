//
//  DuplicatePhotoCell.swift
//  iClean
//
//  Selectable 120pt thumbnail used inside duplicate groups; a half-second
//  long press opens the full-screen photo preview sheet.
//

import SwiftUI
import Photos

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

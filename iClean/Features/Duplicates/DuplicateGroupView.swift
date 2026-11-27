//
//  DuplicateGroupView.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  Card for a single duplicate group: a horizontally scrolling row of
//  selectable thumbnails with "select all but one" and delete actions.
//

import SwiftUI
import Photos

/// Displays one candidate duplicate group with local selection and a parent-supplied delete action.
struct DuplicateGroupView: View {
    let group: DuplicateGroup
    let onDelete: ([PHAsset]) -> Void
    @State private var selectedAssets: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(group.assets.count) identical photos")
                .font(.headline)
                .foregroundColor(AppTheme.ink)

            // Toggle selection by asset identifier while keeping thumbnails horizontally scrollable.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(group.assets, id: \.localIdentifier) { asset in
                        DuplicatePhotoCell(
                            asset: asset,
                            isSelected: selectedAssets.contains(asset.localIdentifier),
                            onTap: {
                                if selectedAssets.contains(asset.localIdentifier) {
                                    selectedAssets.remove(asset.localIdentifier)
                                } else {
                                    selectedAssets.insert(asset.localIdentifier)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 5)
            }

            HStack {
                Button(action: {
                    // Preserve the group's first asset and select every remaining asset for deletion.
                    selectedAssets.removeAll()
                    for asset in group.assets.dropFirst() {
                        selectedAssets.insert(asset.localIdentifier)
                    }
                }) {
                    Text("Select All But One")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .retroPanel(fill: AppTheme.pickerPink, cornerRadius: 8)
                }
                .buttonStyle(.plain)

                Spacer()

                // Forward the selected assets, then clear local selection without waiting for deletion.
                if !selectedAssets.isEmpty {
                    Button(action: {
                        let assetsToDelete = group.assets.filter { selectedAssets.contains($0.localIdentifier) }
                        onDelete(assetsToDelete)
                        selectedAssets.removeAll()
                    }) {
                        Label("Delete \(selectedAssets.count)", systemImage: "trash")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .retroPanel(fill: AppTheme.coral, cornerRadius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .retroPanel(cornerRadius: 15)
    }
}

struct DuplicateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        DuplicateGroupView(group: DuplicateGroup(assets: [])) { _ in }
            .padding()
    }
}


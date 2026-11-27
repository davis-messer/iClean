//
//  DuplicatesView.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  The Duplicates screen: scan progress, empty/initial states, and the list
//  of duplicate groups.
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
                            .foregroundColor(viewModel.hasScanned ? AppTheme.tangerineOrange : AppTheme.ink.opacity(0.5))
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
                                    .retroPanel(fill: AppTheme.tangerineOrange, cornerRadius: 12)
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

struct DuplicatePhotosView_Previews: PreviewProvider {
    static var previews: some View {
        DuplicatePhotosView()
    }
}

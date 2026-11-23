//  SortingView.swift
//  iClean
//
//  Created by Davis Messer on 11/11/26.
//
//  The Sort screen: switches between loading, starting-photo selection,
//  the swipeable card stack with delete/menu/keep actions, and the
//  all-done state, plus the pop-up action menu overlay.

import SwiftUI
import Photos

// Coordinates library loading, starting-photo selection, the sorting stack, and its action menu.
struct SortingView: View {
    @ObservedObject var viewModel: SortingViewModel

    var body: some View {
        ZStack {
            // Transparent so ContentView's graph-paper background shows through.
            Color.clear

            // Switch between loading, library selection, completion, and active sorting.
            VStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.ink)
                        Text("Loading Photos...")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.ink)
                    }
                    .padding(30)
                    .retroPanel()
                } else if !viewModel.hasStartedSorting {
                    if viewModel.libraryAssets.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.ink.opacity(0.5))
                            Text("No Photos")
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.ink)
                            Text("Your photo library is empty.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.ink.opacity(0.6))
                        }
                        .padding(30)
                        .retroPanel()
                    } else {
                        PhotoLibraryView(assets: viewModel.libraryAssets) { asset in
                            viewModel.startSorting(from: asset)
                        }
                    }
                } else if viewModel.images.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.ink.opacity(0.5))
                        Text("All Done")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.ink)
                        Text("You've reached the end of your library!")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.ink.opacity(0.6))

                        if !viewModel.pendingDeletions.isEmpty {
                            Button(action: { viewModel.commitDeletions() }) {
                                Label(
                                    "Delete \(viewModel.pendingDeletions.count) Photo\(viewModel.pendingDeletions.count == 1 ? "" : "s")",
                                    systemImage: "trash"
                                )
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .retroPanel(fill: AppTheme.coral, cornerRadius: 12)
                            }
                            .buttonStyle(.plain)
                            .padding(.top)
                        }
                    }
                    .padding(30)
                    .retroPanel()
                } else {
                    // Stack photos front-to-back and forward drag events to the view model.
                    GeometryReader { geo in
                        ZStack {
                            ForEach(Array(viewModel.images.enumerated()), id: \.element.id) { index, photo in
                                DraggablePhotoCard(
                                    photo: photo,
                                    index: index,
                                    containerWidth: geo.size.width,
                                    onDragChanged: { value in
                                        viewModel.updatePhotoOffset(id: photo.id, value: value, containerWidth: geo.size.width)
                                    },
                                    onDragEnded: { value in
                                        viewModel.handleSwipeEnded(id: photo.id, value: value, containerWidth: geo.size.width)
                                    }
                                )
                                .zIndex(Double(viewModel.images.count - index))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }

                    // Manual delete, commit-pending-deletions, and keep actions.
                    HStack(spacing: 50) {
                        VStack(spacing: 10) {
                            Button(action: { viewModel.swipePhotoLeft() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                            }
                            .buttonStyle(.plain)
                            .retroCircle(fill: AppTheme.coral)
                            Text("Delete")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.ink)
                        }

                        VStack(spacing: 10) {
                            Button(action: { viewModel.commitDeletions() }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 52, height: 52)
                            }
                            .buttonStyle(.plain)
                            .retroCircle(fill: AppTheme.coral)
                            .opacity(viewModel.pendingDeletions.isEmpty ? 0.5 : 1)
                            .disabled(viewModel.pendingDeletions.isEmpty)
                            Text("Delete \(viewModel.pendingDeletions.count)")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.ink)
                        }

                        VStack(spacing: 10) {
                            Button(action: { viewModel.swipePhotoRight() }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                            }
                            .buttonStyle(.plain)
                            .retroCircle(fill: AppTheme.teal)
                            Text("Keep")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.ink)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .onAppear {
                viewModel.requestPhotoLibraryAccess()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

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
    @StateObject private var viewModel = SortingViewModel()
    @State private var showMenu = false

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

                        Button(action: { viewModel.chooseNewStart() }) {
                            Label("Choose New Start", systemImage: "square.grid.2x2")
                                .font(.headline)
                                .foregroundColor(AppTheme.ink)
                                .padding()
                                .retroPanel(fill: AppTheme.teal, cornerRadius: 12)
                        }
                        .buttonStyle(.plain)

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

                    // Manual delete/keep actions flank the menu launcher.
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
                            Button(action: { toggleMenu() }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(AppTheme.ink)
                                    .frame(width: 52, height: 52)
                            }
                            .buttonStyle(.plain)
                            .retroCircle(fill: AppTheme.cream)
                            .opacity(showMenu ? 0 : 1)
                            Text("Menu")
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

            // Overlay the action panel; its rounded tab replaces the hidden menu launcher.
            if showMenu {
                // Dim the sorting screen and dismiss the menu when its backdrop is tapped.
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                    .onTapGesture { toggleMenu() }
                    .transition(.opacity)

                SortMenuPopupView(
                    pendingDeletionCount: viewModel.pendingDeletions.count,
                    isExpanded: showMenu,
                    onClose: toggleMenu,
                    onDelete: {
                        toggleMenu()
                        viewModel.commitDeletions()
                    },
                    onChooseStart: {
                        toggleMenu()
                        viewModel.chooseNewStart()
                    }
                )
                .padding(.horizontal, 45)
                .frame(maxHeight: .infinity, alignment: .bottom)
                // The dome hangs off the panel's bottom edge into the space
                // the menu button occupied.
                .padding(.bottom, 30)
                .transition(.scale(scale: 0.05, anchor: .bottom).combined(with: .opacity))
            }
        }
    }

    /// Opens or closes the action menu using the same spring animation in either direction.
    private func toggleMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showMenu.toggle()
        }
    }
}

//
//  ContentView.swift
//  iClean
//
//  The app's root view: a retro segmented page picker that switches between
//  the Sort and Duplicates screens over the shared graph-paper background.
//

import SwiftUI

/// The two top-level pages of the app.
enum Tab: String, CaseIterable, Identifiable {
    case sort = "Sort"
    case duplicates = "Duplicates"

    var id: Self { self }
}

/// Hosts the Sort and Duplicates pages over a shared graph-paper background.
struct ContentView: View {
    @State private var selectedTab: Tab = .sort
    @State private var pendingTab: Tab?
    @State private var hasContinued = false
    @State private var showLeaveSortConfirmation = false
    @StateObject private var sortingViewModel = SortingViewModel()

    var body: some View {
        ZStack {
            GraphPaperBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !hasContinued {
                    WelcomeView {
                        hasContinued = true
                    }
                } else {
                    switch selectedTab {
                    case .sort:
                        SortingView(viewModel: sortingViewModel)
                    case .duplicates:
                        DuplicatePhotosView()
                    }
                }
            }
        }
        .fontDesign(.rounded)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if hasContinued {
                CustomTabBarView(selectedTab: $selectedTab) { tab in
                    if selectedTab == .sort && tab != .sort && !sortingViewModel.pendingDeletions.isEmpty {
                        pendingTab = tab
                        showLeaveSortConfirmation = true
                    } else {
                        selectedTab = tab
                    }
                }
            }
        }
        .alert("Leave Sorting?", isPresented: $showLeaveSortConfirmation) {
            Button("Leave", role: .destructive) {
                if let pendingTab {
                    selectedTab = pendingTab
                }
                pendingTab = nil
            }
            Button("Stay", role: .cancel) {
                pendingTab = nil
            }
        } message: {
            Text("You have \(sortingViewModel.pendingDeletions.count) photo\(sortingViewModel.pendingDeletions.count == 1 ? "" : "s") queued for deletion that won't be deleted.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

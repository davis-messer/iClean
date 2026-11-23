//
//  ContentView.swift
//  iClean
//
//  The app's root view: a retro segmented page picker that switches between
//  the Sort and Duplicates screens over the shared graph-paper background.
//

import SwiftUI

/// The two top-level pages of the app.
enum Page: String, CaseIterable, Identifiable {
    case sort = "Sort"
    case duplicates = "Duplicates"

    var id: Self { self }
}

/// Hosts the Sort and Duplicates pages over a shared graph-paper background.
struct ContentView: View {
    @State private var selectedPage: Page?
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
                } else if let page = selectedPage {
                    HStack {
                        Button {
                            if page == .sort && !sortingViewModel.pendingDeletions.isEmpty {
                                showLeaveSortConfirmation = true
                            } else {
                                selectedPage = nil
                            }
                        } label: {
                            Label("Menu", systemImage: "chevron.left")
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .retroPanel(fill: AppTheme.pickerPink, cornerRadius: 10)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    switch page {
                    case .sort:
                        SortingView(viewModel: sortingViewModel)
                    case .duplicates:
                        DuplicatePhotosView()
                    }
                } else {
                    MenuView { page in
                        selectedPage = page
                    }
                }
            }
        }
        .fontDesign(.rounded)
        .alert("Leave Sorting?", isPresented: $showLeaveSortConfirmation) {
            Button("Leave", role: .destructive) {
                selectedPage = nil
            }
            Button("Stay", role: .cancel) { }
        } message: {
            Text("You have \(sortingViewModel.pendingDeletions.count) photo\(sortingViewModel.pendingDeletions.count == 1 ? "" : "s") queued for deletion that won't be deleted.")
        }
    }

    /// A chunky segmented control with the retro outline-and-hard-shadow look.
    private var pagePicker: some View {
        HStack(spacing: 4) {
            ForEach(Page.allCases) { page in
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        selectedPage = page
                    }
                } label: {
                    Text(page.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedPage == page {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.teal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppTheme.ink, lineWidth: 2)
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .retroPanel(fill: AppTheme.pickerPink, cornerRadius: 14)
    }
}

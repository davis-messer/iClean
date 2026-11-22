//
//  ContentView.swift
//  iClean
//
//  The app's root view: a retro segmented page picker that switches between
//  the Sort and Duplicates screens over the shared graph-paper background.
//

import SwiftUI

/// Hosts the Sort and Duplicates pages over a shared graph-paper background.
struct ContentView: View {
    /// The two top-level pages of the app.
    private enum Page: String, CaseIterable, Identifiable {
        case sort = "Sort"
        case duplicates = "Duplicates"

        var id: Self { self }
    }

    @State private var selectedPage: Page = .sort
    @State private var hasContinued = false

    var body: some View {
        ZStack {
            GraphPaperBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if hasContinued {
                    pagePicker
                        .padding()

                    switch selectedPage {
                    case .sort:
                        SortingView()
                    case .duplicates:
                        DuplicatePhotosView()
                    }
                } else {
                    WelcomeView {
                        hasContinued = true
                    }
                }
            }
        }
        .fontDesign(.rounded)
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

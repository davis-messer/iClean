
import SwiftUI

/// Lists the app's pages as large buttons after the welcome screen.
struct MenuView: View {
    let onSelect: (Page) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Menu")
                .font(.title.bold())
                .foregroundColor(AppTheme.ink)

            menuButton(title: "Sort", icon: "photo.stack", fill: AppTheme.teal) {
                onSelect(.sort)
            }

            menuButton(title: "Duplicates", icon: "square.on.square", fill: AppTheme.coral) {
                onSelect(.duplicates)
            }
        }
        .padding(32)
        .retroPanel(fill: AppTheme.cream, cornerRadius: 20)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func menuButton(title: String, icon: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(AppTheme.ink)
                .frame(maxWidth: .infinity)
                .padding()
                .retroPanel(fill: fill, cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }
}
//
//  AppTheme.swift
//  iClean
//
//  App-wide retro styling shared by every screen: the color palette,
//  the sticker-look retroPanel/retroCircle view modifiers, and the
//  graph-paper background.
//

import SwiftUI

/// Shared colors for the app's retro pink aesthetic.
enum AppTheme {
    static let babyPink = Color(red: 1.0, green: 0.85, blue: 0.89)
    static let pickerPink = Color(red: 1.0, green: 0.93, blue: 0.95)
    static let gridLinePink = Color(red: 0.94, green: 0.6, blue: 0.7)
    static let cream = Color(red: 1.0, green: 0.97, blue: 0.9)
    static let ink = Color(red: 0.13, green: 0.12, blue: 0.14)
    static let teal = Color(red: 0.36, green: 0.84, blue: 0.78)
    static let coral = Color(red: 1.0, green: 0.47, blue: 0.44)
}

/// Retro "sticker" treatments: a bold ink outline with a hard offset shadow.
extension View {
    /// Adds a rounded filled panel, ink outline, and fixed offset shadow behind the view.
    func retroPanel(fill: Color = AppTheme.cream, cornerRadius: CGFloat = 14) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.ink)
                    .offset(x: 3, y: 4)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.ink, lineWidth: 2)
            }
        )
    }

    /// Adds the circular version of the sticker treatment, sized by the view's bounds.
    func retroCircle(fill: Color) -> some View {
        background(
            ZStack {
                Circle()
                    .fill(AppTheme.ink)
                    .offset(x: 2.5, y: 3.5)
                Circle()
                    .fill(fill)
                Circle()
                    .stroke(AppTheme.ink, lineWidth: 2)
            }
        )
    }
}

/// A baby-pink background with evenly spaced graph lines, like grid paper.
struct GraphPaperBackground: View {
    private let gridSpacing: CGFloat = 24

    var body: some View {
        Canvas { context, size in
            var lines = Path()

            // Collect vertical and horizontal grid lines, then stroke them in one pass.
            var x: CGFloat = 0
            while x <= size.width {
                lines.move(to: CGPoint(x: x, y: 0))
                lines.addLine(to: CGPoint(x: x, y: size.height))
                x += gridSpacing
            }

            var y: CGFloat = 0
            while y <= size.height {
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
                y += gridSpacing
            }

            context.stroke(lines, with: .color(AppTheme.gridLinePink.opacity(0.35)), lineWidth: 0.5)
        }
        .background(AppTheme.babyPink)
    }
}

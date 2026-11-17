//
//  SortMenuPopupView.swift
//  iClean
//
//  The Sort screen's pop-up action menu (commit pending deletions, choose a
//  new starting photo) and the custom dome-tabbed panel shape it sits on.
//

import SwiftUI

/// Offers pending-photo deletion and starting-photo selection above a rounded close tab.
/// Actions are supplied by the parent, which owns menu visibility and sorting state.
struct SortMenuPopupView: View {
    let pendingDeletionCount: Int
    let isExpanded: Bool
    let onClose: () -> Void
    let onDelete: () -> Void
    let onChooseStart: () -> Void

    private let shape = DomePanelShape()

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onDelete) {
                Label(
                    pendingDeletionCount == 0
                        ? "Trash"
                        : "Delete \(pendingDeletionCount) Photo\(pendingDeletionCount == 1 ? "" : "s")",
                    systemImage: "trash"
                )
                .font(.headline)
                .foregroundColor(pendingDeletionCount == 0 ? AppTheme.ink.opacity(0.35) : .white)
                .frame(maxWidth: .infinity)
                .padding()
                .retroPanel(
                    fill: pendingDeletionCount == 0 ? AppTheme.cream : AppTheme.coral,
                    cornerRadius: 12
                )
            }
            .buttonStyle(.plain)
            .disabled(pendingDeletionCount == 0)

            Button(action: onChooseStart) {
                Label("Choose Starting Photo", systemImage: "square.grid.2x2")
                    .font(.headline)
                    .foregroundColor(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .retroPanel(fill: AppTheme.teal, cornerRadius: 12)
            }
            .buttonStyle(.plain)
        }
        .opacity(isExpanded ? 1 : 0)
        .padding(16)
        // Reserve the full tab height so options stay inside the rectangular panel body.
        .padding(.bottom, shape.domeRadius + shape.tabExtension)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            ZStack {
                shape
                    .fill(AppTheme.ink)
                    .offset(x: 3, y: 4)
                shape
                    .fill(AppTheme.cream)
                shape
                    .stroke(AppTheme.ink, lineWidth: 2)
            }
        )
        // Keep the close icon and its 52pt hit target together at the tab's bottom.
        .overlay(alignment: .bottom) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(AppTheme.ink)
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close menu")
        }
    }
}

/// Draws the panel and its elongated, semicircle-ended tab as one continuous outline.
/// The tab has straight sides (`tabExtension`) and a rounded end (`domeRadius`).
struct DomePanelShape: Shape {
    var cornerRadius: CGFloat = 15
    var domeRadius: CGFloat = 26
    var tabExtension: CGFloat = 45

    /// Reserves the bottom of the bounds for the tab and traces the panel clockwise around it.
    func path(in rect: CGRect) -> Path {
        let bodyMaxY = rect.maxY - domeRadius - tabExtension
        let midX = rect.midX
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))

        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            radius: cornerRadius
        )

        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyMaxY - cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: bodyMaxY),
            tangent2End: CGPoint(x: rect.maxX - cornerRadius, y: bodyMaxY),
            radius: cornerRadius
        )

        // Bottom edge in to the dome, around the semicircle, and back out
        let shoulderRadius: CGFloat = 20
        let rightX = midX + domeRadius
        let leftX = midX - domeRadius

        path.addLine(to: CGPoint(
            x: rightX + shoulderRadius,
            y: bodyMaxY
        ))
        path.addQuadCurve(
            to: CGPoint(x: rightX, y: bodyMaxY + shoulderRadius),
            control: CGPoint(x: rightX, y: bodyMaxY)
        )

        path.addLine(to: CGPoint(
            x: rightX,
            y: bodyMaxY + tabExtension
        ))
        path.addArc(
            center: CGPoint(x: midX, y: bodyMaxY + tabExtension),
            radius: domeRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.addLine(to: CGPoint(
            x: leftX,
            y: bodyMaxY + shoulderRadius
        ))
        path.addQuadCurve(
            to: CGPoint(x: leftX - shoulderRadius, y: bodyMaxY),
            control: CGPoint(x: leftX, y: bodyMaxY)
        )

        // Bottom-left corner and left edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: bodyMaxY))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: bodyMaxY),
            tangent2End: CGPoint(x: rect.minX, y: bodyMaxY - cornerRadius),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.minY),
            tangent2End: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            radius: cornerRadius
        )

        path.closeSubpath()
        return path
    }
}

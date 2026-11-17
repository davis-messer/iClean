//
//  PhotoCardStack.swift
//  iClean
//
//  Card views for the sorting stack: the static framed photo card and the
//  draggable wrapper that adds depth styling, swipe-direction overlays, and
//  front-card-only drag gestures.
//

import SwiftUI

/// Fits a photo inside a rounded card with an ink border and hard offset shadow.
struct PhotoCardView: View {
    let photo: PhotoItem

    var body: some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppTheme.ink)
                    .offset(x: 4, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppTheme.ink, lineWidth: 2.5)
            )
    }
}

/// Applies stack styling, swipe feedback, and front-card-only dragging to a photo card.
struct DraggablePhotoCard: View {
    let photo: PhotoItem
    let index: Int
    let containerWidth: CGFloat
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        PhotoCardView(photo: photo)
            .offset(photo.offset)
            .rotationEffect(.degrees(photo.degrees))
            .opacity(index == 0 ? 1.0 : 0.7)
            .scaleEffect(index == 0 ? 1.0 : 0.95)
            .overlay(swipeIndicatorOverlay)
            .gesture(index == 0 ? dragGesture : nil)
    }

    /// Shows directional feedback only after the front card moves more than 50pt horizontally.
    @ViewBuilder
    private var swipeIndicatorOverlay: some View {
        if index == 0 {
            if photo.offset.width < -50 {
                deleteIndicator
            } else if photo.offset.width > 50 {
                keepIndicator
            }
        }
    }

    /// Intensifies a red trash overlay with leftward travel, capped at 50% opacity.
    private var deleteIndicator: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(
                Color.red.opacity(
                    min(abs(photo.offset.width) / CGFloat(200), CGFloat(0.5))
                )
            )
            .overlay(
                Image(systemName: "trash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            )
    }

    /// Intensifies a green checkmark overlay with rightward travel, capped at 50% opacity.
    private var keepIndicator: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(
                Color.green.opacity(
                    min(photo.offset.width / CGFloat(200), CGFloat(0.5))
                )
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            )
    }

    /// Forwards drag updates and release events after 10pt of movement.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged(onDragChanged)
            .onEnded(onDragEnded)
    }
}

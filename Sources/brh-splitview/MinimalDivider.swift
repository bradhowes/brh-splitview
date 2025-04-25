import SwiftUI

/**
 Divider view that provides a handle for dragging.
 */
struct MinimalDivider: View {
  let orientation: SplitViewOrientation
  let dividerConstraints: SplitViewConstraints
  let color: Color

  init(
    for orientation: SplitViewOrientation,
    dividerConstraints: SplitViewConstraints,
    color: Color = Color.indigo,
  ) {
    self.orientation = orientation
    self.dividerConstraints = dividerConstraints
    self.color = color
  }

  var body: some View {
    ZStack {
      switch orientation {
      case .horizontal:
        Rectangle()
          .fill(color)
          .frame(width: dividerConstraints.visibleSpan)
          .padding(0)

      case .vertical:
        Rectangle()
          .fill(color)
          .frame(height: dividerConstraints.visibleSpan)
          .padding(0)
      }
    }
    .contentShape(Rectangle())
  }
}


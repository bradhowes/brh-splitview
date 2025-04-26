// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Divider view that provides a handle for dragging.
 */
public struct MinimalDivider: View {
  let color: Color
  @Environment(\.splitViewConfiguration) var config

  public init(color: Color = .gray) {
    self.color = color
  }

  public var body: some View {
    ZStack {
      switch config.orientation {
      case .horizontal:
        Rectangle()
          .fill(color)
          .frame(width: config.visibleDividerSpan)
          .padding(0)

      case .vertical:
        Rectangle()
          .fill(color)
          .frame(height: config.visibleDividerSpan)
          .padding(0)
      }
    }
    .contentShape(Rectangle())
  }
}


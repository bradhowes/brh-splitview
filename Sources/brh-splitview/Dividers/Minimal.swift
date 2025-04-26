// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Divider view that provides a handle for dragging.
 */
public struct MinimalDivider: View {
  private let color: Color
  @Environment(\.splitViewConfiguration) private var config
  private var isHorizontal: Bool { config.orientation.vertical }
  private var visibleDividerSpan: Double { config.visibleDividerSpan }

  public init(color: Color = .gray) {
    self.color = color
  }

  public var body: some View {
    ZStack {
      Rectangle()
        .fill(color)
        .frame(width: isHorizontal ? nil : visibleDividerSpan, height: isHorizontal ? visibleDividerSpan : nil)
        .padding(0)
    }
    .contentShape(Rectangle())
  }
}

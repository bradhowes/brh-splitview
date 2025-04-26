// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Divider view used for debugging layouts
 */
public struct DebugDivider: View {
  private let visibleDividerSpan: Double = 16
  private let invisibleDividerSpan: Double = 32

  @Environment(\.splitViewConfiguration) var config
  private var horizontal: Bool { config.orientation.horizontal }

  init() {}

  public var body: some View {
    ZStack(alignment: .center) {
      Color.blue.opacity(0.50)
        .frame(width: horizontal ? nil : invisibleDividerSpan, height: horizontal ? invisibleDividerSpan : nil)
      Color.red.opacity(1.0)
        .frame(width: horizontal ? nil : visibleDividerSpan, height: horizontal ? visibleDividerSpan : nil)
    }
  }
}

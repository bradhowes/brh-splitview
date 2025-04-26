// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Divider view used for debugging layouts
 */
public struct DebugDivider: View {
  private let visibleDividerSpan: Double = 16
  private let invisibleDividerSpan: Double = 32

  @Environment(\.splitViewConfiguration) private var config
  private var isHorizontal: Bool { config.orientation.vertical }

  init() {}

  public var body: some View {
    ZStack(alignment: .center) {
      Color.blue.opacity(0.50)
        .frame(
          width: isHorizontal ? nil : invisibleDividerSpan,
          height: isHorizontal ? invisibleDividerSpan : nil)
      Color.red.opacity(1.0)
        .frame(
          width: isHorizontal ? nil : visibleDividerSpan,
          height: isHorizontal ? visibleDividerSpan : nil)
    }
  }
}

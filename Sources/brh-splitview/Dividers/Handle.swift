// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Divider view that provides a handle for dragging.
 */
public struct HandleDivider: View {
  private let dividerColor: Color
  private let handleColor: Color
  private let dotColor: Color
  private let handleLength: Double
  private let handleWidth: Double
  private let paddingInsets: Double
  @Environment(\.splitViewConfiguration) private var config

  public init(
    dividerColor: Color = .gray,
    handleColor: Color = .yellow,
    dotColor: Color = .black,
    handleLength: Double = 32.0,
    handleWidth: Double = 12.0,
    paddingInsets: Double = 6.0
  ) {
    self.dividerColor = dividerColor
    self.handleColor = handleColor
    self.dotColor = dotColor
    self.handleLength = handleLength
    self.handleWidth = handleWidth
    self.paddingInsets = paddingInsets
  }

  public var body: some View {
    ZStack {
      switch config.orientation {
      case .horizontal:
        // Create a vertical divider
        Rectangle()
          .fill(dividerColor)
          .frame(width: config.visibleDividerSpan)
          .padding(0)
          .contentShape(.interaction, Rectangle())
          .frame(width: handleWidth * 2)

        RoundedRectangle(cornerRadius: handleWidth / 2)
          .fill(handleColor)
          .frame(width: handleWidth, height: handleLength)
          .padding(EdgeInsets(top: paddingInsets, leading: 0, bottom: paddingInsets, trailing: 0))

        VStack {
          Color(dotColor)
            .frame(width: 2, height: 2)
          Color(dotColor)
            .frame(width: 2, height: 2)
        }

      case .vertical:
        // Create a horizontal divider
        Rectangle()
          .fill(dividerColor)
          .frame(height: config.visibleDividerSpan)
          .padding(0)
          .contentShape(.interaction, Rectangle())
          .frame(height: handleWidth * 2)

        RoundedRectangle(cornerRadius: handleLength / 2)
          .fill(handleColor)
          .frame(width: handleLength, height: handleWidth)
          .padding(EdgeInsets(top: 0, leading: paddingInsets, bottom: 0, trailing: paddingInsets))

        HStack {
          Color(dotColor)
            .frame(width: 2, height: 2)
          Color(dotColor)
            .frame(width: 2, height: 2)
        }
      }
    }
    .contentShape(Rectangle())
  }
}

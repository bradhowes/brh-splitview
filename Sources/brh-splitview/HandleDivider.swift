import SwiftUI

/**
 Divider view that provides a handle for dragging.
 */
struct HandleDivider: View {
  let orientation: SplitViewOrientation
  let dividerConstraints: SplitViewConstraints
  let dividerColor: Color
  let handleColor: Color
  let handleLength: Double
  let handleWidth: Double
  let paddingInsets: Double

  init(
    for orientation: SplitViewOrientation,
    dividerConstraints: SplitViewConstraints,
    dividerColor: Color = .gray,
    handleColor: Color = .indigo,
    handleLength: Double = 32.0,
    handleWidth: Double = 12.0,
    paddingInsets: Double = 6.0
  ) {
    self.orientation = orientation
    self.dividerConstraints = dividerConstraints
    self.dividerColor = .gray
    self.handleColor = handleColor
    self.handleLength = handleLength
    self.handleWidth = handleWidth
    self.paddingInsets = paddingInsets
  }

  var body: some View {
    ZStack {
      switch orientation {
      case .horizontal:

        Rectangle()
          .fill(dividerColor)
          .frame(width: dividerConstraints.visibleSpan)
          .padding(0)
          .contentShape(.interaction, Rectangle())
          .frame(width: handleWidth * 2)

        RoundedRectangle(cornerRadius: handleWidth / 2)
          .fill(handleColor)
          .frame(width: handleWidth, height: handleLength)
          .padding(EdgeInsets(top: paddingInsets, leading: 0, bottom: paddingInsets, trailing: 0))

        VStack {
          Color.black
            .frame(width: 2, height: 2)
          Color.black
            .frame(width: 2, height: 2)
        }

      case .vertical:

        Rectangle()
          .fill(dividerColor)
          .frame(height: dividerConstraints.visibleSpan)
          .padding(0)
          .contentShape(.interaction, Rectangle())
          .frame(height: handleWidth * 2)

        RoundedRectangle(cornerRadius: handleWidth / 2)
          .fill(handleColor)
          .frame(width: handleLength, height: handleWidth)
          .padding(EdgeInsets(top: 0, leading: paddingInsets, bottom: 0, trailing: paddingInsets))

        HStack {
          Color.black
            .frame(width: 2, height: 2)
          Color.black
            .frame(width: 2, height: 2)
        }
      }
    }
    .contentShape(Rectangle())
  }
}


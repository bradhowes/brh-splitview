import SwiftUI

/**
 Divider view used for debugging layouts
 */
public struct DebugDivider: View {
  private let orientation: SplitViewOrientation
  public let visibleSpan: Double = 16
  public let invisibleSpan: Double = 32
  public var horizontal: Bool { orientation.horizontal }
  public var vertical: Bool { orientation.vertical }

  init(for orientation: SplitViewOrientation) {
    self.orientation = orientation == .horizontal ? .vertical : .horizontal
  }

  public var body: some View {
    ZStack(alignment: .center) {
      Color.blue.opacity(0.50)
        .frame(width: horizontal ? nil : invisibleSpan, height: horizontal ? invisibleSpan : nil)
      Color.red.opacity(1.0)
        .frame(width: horizontal ? nil : visibleSpan, height: horizontal ? visibleSpan : nil)
    }
  }
}

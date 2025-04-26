// Copyright © 2025 Brad Howes. All rights reserved.

/**
 The orientation of the two views with a divider view between them. In the `horizontal` orientation,
 the secondary view appears to the right of the primary view and the divider view. In the `vertical`
 orientation, the secondary view appears below the primary view and the divider view.
 */
public enum SplitViewOrientation: Equatable {
  case horizontal
  case vertical

  public var horizontal: Bool { self == .horizontal }
  public var vertical: Bool { self == .vertical }
}

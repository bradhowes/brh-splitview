// Copyright © 2025 Brad Howes. All rights reserved.

/**
 The indication of the visible panes in a split view. The `primary` is the left or top view
 and `secondary` is the other one. There are aliases for `left`, `right`, `top`, and `bottom` and
 definitions for `none` and `both`.
 */
public struct SplitViewPanes: OptionSet, Sendable, Equatable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let none = SplitViewPanes([])
  public static let primary = SplitViewPanes(rawValue: 1 << 0)
  public static let secondary = SplitViewPanes(rawValue: 1 << 1)
  public static let both = SplitViewPanes(rawValue: primary.rawValue | secondary.rawValue)

  public static let left = primary
  public static let right = secondary

  public static let top = primary
  public static let bottom = secondary

  public var primary: Bool { self.contains(.primary) }
  public var secondary: Bool { self.contains(.secondary) }
  public var both: Bool { primary && secondary }
}

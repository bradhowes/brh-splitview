// Copyright © 2025 Brad Howes. All rights reserved.

/**
 The indication of the visible panes in a split view. The `primary` is the left or top view
 and `secondary` is the other one. There are aliases for `left`, `right`, `top`, and `bottom` and
 definitions for `none` and `both`.
 */
@available(*, deprecated, renamed: "SplitViewVisiblePanes")
public typealias SplitViewPanes = SplitViewVisiblePanes

public struct SplitViewVisiblePanes: OptionSet, Sendable, Equatable {
  public let rawValue: Int

  /**
   Implementation of `OptionSet` protocol.
  
   - parameter rawValue: the integer value that represents the options to hold
   */
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Constant to indicate no panes.
  public static let none = Self([])
  /// Constant to indicate the primary pane.
  public static let primary = Self(rawValue: 1 << 0)
  /// Constant to indicate the secondary pane.
  public static let secondary = Self(rawValue: 1 << 1)
  /// Constant to indicate both primary and secondary panes.
  public static let both = Self(rawValue: primary.rawValue | secondary.rawValue)
  /// Alias to the primary pane
  public static let left = primary
  /// Alias to the primary pane
  public static let top = primary
  /// Alias to the secondary pane
  public static let right = secondary
  /// Alias to the secondary pane
  public static let bottom = secondary

  /// @returns `true` if the primary pane is visible
  public var primary: Bool { self.contains(.primary) }
  /// @returns `true` if the secondary pane is visible
  public var secondary: Bool { self.contains(.secondary) }
  /// @returns `true` if both panes are visible
  public var both: Bool { primary && secondary }
}

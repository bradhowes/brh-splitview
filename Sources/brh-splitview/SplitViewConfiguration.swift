// Copyright © 2025 Brad Howes. All rights reserved.

/**
 Configurable parameters for a SplitView. These are injected into a `SplitView` via the
 `.splitViewConfiguration` `View` modifier.
 */
public struct SplitViewConfiguration: Equatable {

  public enum DraggableRangeType: Equatable {
    /// A range defined over the values [0.0, 1.0] which act as percentages of some length. For instance, a value of [0.2, 0.8]
    /// and a view width of 300, would restrict horizontal movement to [60, 240] of the full width.
    case normalized(ClosedRange<Double>)
    /// A range defined over two constants `lower`, `upper` so that movement is resticted to [lower, upper] regardless of view
    /// dimension and size.
    case fixedLength(lowerSpan: Double, upperSpan: Double)

    public func lowerBound(for span: Double) -> Double {
      return switch self {
      case let .normalized(range): range.lowerBound
      case let .fixedLength(lowerSpan, _): span == 0.0 ? 0.0 : (lowerSpan / span)
      }
    }

    public func upperBound(for span: Double) -> Double {
      return switch self {
      case let .normalized(range): range.upperBound
      case let .fixedLength(_, upperSpan): span == 0.0 ? 1.0 : (1.0 - upperSpan / span)
      }
    }

    public func bounds(for span: Double) -> ClosedRange<Double> {
      return switch self {
      case let .normalized(range): range
      case let .fixedLength(lowerSpan, upperSpan): span == 0.0 ? (0.0...1.0) : ((lowerSpan / span)...(1.0 - upperSpan / span))
      }
    }
  }

  /// The orientation of the views, either `.horizontal` or `.vertical`.
  public let orientation: SplitViewOrientation
  /// The region of the SplitView's span that can be moved over. The default is to be able to move the divider everywhere.
  public let draggableRange: DraggableRangeType
  /// Whether to hide a pane when dragging stops past its minimum fraction value. Supports zero, one, or both child views.
  public let dragToHidePanes: SplitViewVisiblePanes
  /// Which pane if any to close when the divider view receives a double-click event.
  public let doubleClickToClose: SplitViewVisiblePanes
  /// The visible span of the divider view. The actual hit area for touch events can be larger depending on the divider config.
  public let visibleDividerSpan: Double
  /// The lower bound to use while dragging (honors the contents of `dragToHidePanes`)
  public func dragLowerBound(for span: Double) -> Double {
    dragToHidePanes.contains(.primary) ? 0.0 : draggableRange.lowerBound(for: span)
  }
  /// The upper bound to use while dragging (honors the contents of `dragToHidePanes`)
  public func dragUpperBound(for span: Double) -> Double {
    dragToHidePanes.contains(.secondary) ? 1.0 : draggableRange.upperBound(for: span)
  }
  /// The range defined by `dragLowerBound` and `dragUpperBound`.
  public func dragBounds(for span: Double) -> ClosedRange<Double> { dragLowerBound(for: span)...dragUpperBound(for: span) }

  public init(
    orientation: SplitViewOrientation,
    draggableRange: ClosedRange<Double>,
    dragToHidePanes: SplitViewVisiblePanes = [],
    doubleClickToClose: SplitViewVisiblePanes = [],
    visibleDividerSpan: Double = 4.0
  ) {
    self.orientation = orientation
    self.draggableRange = .normalized(draggableRange)
    self.dragToHidePanes = dragToHidePanes
    self.doubleClickToClose = doubleClickToClose
    self.visibleDividerSpan = visibleDividerSpan
  }

  public init(
    orientation: SplitViewOrientation,
    draggableRange: DraggableRangeType = .normalized(0.0...1.0),
    dragToHidePanes: SplitViewVisiblePanes = [],
    doubleClickToClose: SplitViewVisiblePanes = [],
    visibleDividerSpan: Double = 4.0
  ) {
    self.orientation = orientation
    self.draggableRange = draggableRange
    self.dragToHidePanes = dragToHidePanes
    self.doubleClickToClose = doubleClickToClose
    self.visibleDividerSpan = visibleDividerSpan
  }
}

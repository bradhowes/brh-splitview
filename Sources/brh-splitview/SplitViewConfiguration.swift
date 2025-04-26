// Copyright © 2025 Brad Howes. All rights reserved.

/**
 Configurable parameters for a SplitView. These are injected into a `SplitView` via the
 `.splitViewConfiguration` `View` modifier.
 */
public struct SplitViewConfiguration: Equatable {
  /// The orientation of the views, either `.horizontal` or `.vertical`.
  public let orientation: SplitViewOrientation
  /// The region of the SplitView's span that can be moved over.
  /// The default is to be able to move the divider everywhere.
  public let draggableRange: ClosedRange<Double>
  /// Whether to hide a pane when dragging stops past its minimum fraction value. Supports zero, one, or both
  /// child views.
  public let dragToHidePanes: SplitViewPanes
  /// Which pane if any to close when the divider view receives a double-click event.
  public let doubleClickToClose: SplitViewPanes
  /// The visible span of the divider view. The actual hit area for touch events can be larger depending on the
  /// definition of the divider.
  public let visibleDividerSpan: Double
  /// The lower bound to use while dragging (honors the contents of `dragToHidePanes`)
  public let dragLowerBound: Double
  /// The upper bound to use while dragging (honors the contents of `dragToHidePanes`)
  public let dragUpperBound: Double
  /// The range defined by `dragLowerBound` and `dragUpperBound`.
  public let dragBounds: ClosedRange<Double>

  public init(
    orientation: SplitViewOrientation,
    draggableRange: ClosedRange<Double> = 0.0...1.0,
    dragToHidePanes: SplitViewPanes = [],
    doubleClickToClose: SplitViewPanes = [],
    visibleDividerSpan: Double = 4.0
  ) {
    self.orientation = orientation
    self.draggableRange = draggableRange
    self.dragToHidePanes = dragToHidePanes
    self.doubleClickToClose = doubleClickToClose
    self.visibleDividerSpan = visibleDividerSpan
    self.dragLowerBound = dragToHidePanes.contains(.primary) ? 0.0 : draggableRange.lowerBound
    self.dragUpperBound = dragToHidePanes.contains(.secondary) ? 1.0 : draggableRange.upperBound
    self.dragBounds = dragLowerBound...dragUpperBound
  }
}

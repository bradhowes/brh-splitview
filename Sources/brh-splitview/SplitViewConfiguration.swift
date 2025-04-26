// Copyright © 2025 Brad Howes. All rights reserved.

/**
 Configurable parameters for a SplitView. These are injected into a `SplitView` via the
 `.splitViewConfiguration` `View` modifier.
 */
public struct SplitViewConfiguration: Equatable {
  /// The orientation of the views, either `.horizontal` or `.vertical`.
  public let orientation: SplitViewOrientation
  /// The minimum fraction that the primary view will be constrained [0-1.0].
  /// The default is to be able to move the divider across the entire contents of the primary view.
  public let minimumPrimaryFraction: Double
  /// The minimum fraction that the secondary view will be constrained [0-1.0].
  /// The default is to be able to move the divider across the entire contents of the secondary view.
  public let minimumSecondaryFraction: Double
  /// Whether to hide a pane when dragging stops past its minimum fraction value. Supports zero, one, or both
  /// child views.
  public let dragToHidePanes: SplitViewPanes
  /// The visible span of the divider view. The actual hit area for touch events can be larger depending on the
  /// definition of the divider.
  public let visibleDividerSpan: Double

  public init(
    orientation: SplitViewOrientation,
    minimumPrimaryFraction: Double = 0.0,
    minimumSecondaryFraction: Double = 0.0,
    dragToHidePanes: SplitViewPanes = [],
    visibleDividerSpan: Double = 4.0
  ) {
    self.orientation = orientation
    self.minimumPrimaryFraction = minimumPrimaryFraction
    self.minimumSecondaryFraction = minimumSecondaryFraction
    self.dragToHidePanes = dragToHidePanes
    self.visibleDividerSpan = visibleDividerSpan
  }
}


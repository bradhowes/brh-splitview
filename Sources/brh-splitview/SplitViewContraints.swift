
/**
 Configurable parameters for a SplitView. They mostly affect drag movements and behavior.
 */
public struct SplitViewConstraints: Equatable {
  /// The minimum fraction that the primary view will be constrained within. A value of `nil` means unconstrained.
  public let minPrimaryFraction: Double
  /// The minimum fraction that the secondary view will be constrained within. A value of `nil` means unconstrained.
  public let minSecondaryFraction: Double
  /// Whether to hide a pane when dragging stops past a min fraction value
  public let dragToHide: SplitViewPanes
  /// The visible span of the divider view. The actual hit area for touch events can be larger depending on the
  /// definition of the divider.
  public let visibleSpan: Double

  public init(
    minPrimaryFraction: Double = 0.0,
    minSecondaryFraction: Double = 0.0,
    dragToHide: SplitViewPanes = [],
    visibleSpan: Double = 16.0
  ) {
    self.minPrimaryFraction = minPrimaryFraction
    self.minSecondaryFraction = minSecondaryFraction
    self.dragToHide = dragToHide
    self.visibleSpan = visibleSpan
  }
}


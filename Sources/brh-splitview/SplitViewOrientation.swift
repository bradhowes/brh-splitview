/**
 The orientation of the two views with a divider view between them
 */
public enum SplitViewOrientation: Equatable {
  case horizontal
  case vertical

  public var horizontal: Bool { self == .horizontal }
  public var vertical: Bool { self == .vertical }
}

// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

internal extension Comparable {

  /**
   Obtain a new value that is clamped to the given range.

   - parameter limits: the range to use
   - returns: new value
   */
  func clamped(to limits: ClosedRange<Self>) -> Self { min(max(self, limits.lowerBound), limits.upperBound) }
}

internal extension Comparable where Self: BinaryFloatingPoint {

  /**
   Obtain a normalized value (0-1.0) over the given range.

   - parameter limits: the range to use
   - returns: normalized value
   */
  func normalize(in limits: ClosedRange<Self>) -> Self { clamped(to: limits) / (limits.upperBound  - limits.lowerBound)}
}

internal extension ClosedRange {

  /**
   Clamp the given value so that it is within our bounds.

   - parameter value to clamp
   - returns: new value
   */
  func clamp(value : Bound) -> Bound { value.clamped(to: self) }
}

internal extension ClosedRange where Bound: BinaryFloatingPoint {

  /**
   Normalize the given value over our bounds.

   - parameter value to normalize
   - returns: normalized value
   */
  func normalize(value: Bound) -> Bound { value.normalize(in: self) }
}

extension EnvironmentValues {
  @Entry public var splitViewConfiguration: SplitViewConfiguration = .init(orientation: .horizontal)
}

extension View {
  public func splitViewConfiguration(_ value: SplitViewConfiguration) -> some View {
    environment(\.splitViewConfiguration, value)
  }
}

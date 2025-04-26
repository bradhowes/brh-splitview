// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

internal extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self { min(max(self, limits.lowerBound), limits.upperBound) }
}

internal extension Comparable where Self: BinaryFloatingPoint {
  func normalize(in limits: ClosedRange<Self>) -> Self { clamped(to: limits) / limits.upperBound }
}

internal extension ClosedRange {
  func clamp(value : Bound) -> Bound { value.clamped(to: self) }
}

internal extension ClosedRange where Bound: BinaryFloatingPoint {
  func normalize(value: Bound) -> Bound { value.clamped(to: self) / self.upperBound }
}

extension EnvironmentValues {
  @Entry public var splitViewConfiguration: SplitViewConfiguration = .init(orientation: .horizontal)
}

extension View {
  public func splitViewConfiguration(_ value: SplitViewConfiguration) -> some View {
    environment(\.splitViewConfiguration, value)
  }
}

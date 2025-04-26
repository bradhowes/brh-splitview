import SnapshotTesting
import SwiftUI
import Testing

@testable import BRHSplitview

@Suite("SplitViewConfiguration") struct SplitViewConfigurationTests {

  @Test func defaultBoundsSetup() throws {
    let svc = SplitViewConfiguration(orientation: .horizontal)
    #expect(svc.draggableRange == 0...1)
    #expect(svc.dragBounds == 0...1)
  }

  @Test(
    "Bounds honors dragToHidePanes",
    arguments: [
      (SplitViewPanes.none, 0.3...0.8),
      (SplitViewPanes.primary, 0.0...0.8),
      (SplitViewPanes.secondary, 0.3...1.0),
      (SplitViewPanes.both, 0.0...1.0),
    ]
  )
  func boundsHonorsDragToHidePanes(run: (SplitViewPanes, ClosedRange<Double>)) throws {
    let svc = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: 0.3...0.8,
      dragToHidePanes: run.0
    )
    #expect(svc.draggableRange == 0.3...0.8)
    #expect(svc.dragBounds == run.1)
    #expect(svc.dragLowerBound == run.1.lowerBound)
    #expect(svc.dragUpperBound == run.1.upperBound)
  }
}

@Suite("SplitViewOrientation") struct SplitViewOrientationTests {

  @Test func testState() {
    #expect(SplitViewOrientation.horizontal.horizontal == true)
    #expect(SplitViewOrientation.horizontal.vertical == false)
    #expect(SplitViewOrientation.vertical.vertical == true)
    #expect(SplitViewOrientation.vertical.horizontal == false)
  }
}

@Suite("SplitViewPanes") struct SplitViewPanesTests {

  @Test func testConditions() {
    #expect(SplitViewPanes.none.primary == false)
    #expect(SplitViewPanes.none.secondary == false)
    #expect(SplitViewPanes.none.both == false)

    #expect(SplitViewPanes.primary.primary == true)
    #expect(SplitViewPanes.primary.secondary == false)
    #expect(SplitViewPanes.primary.both == false)

    #expect(SplitViewPanes.secondary.primary == false)
    #expect(SplitViewPanes.secondary.secondary == true)
    #expect(SplitViewPanes.secondary.both == false)

    #expect(SplitViewPanes.both.primary == true)
    #expect(SplitViewPanes.both.secondary == true)
    #expect(SplitViewPanes.both.both == true)

    #expect(SplitViewPanes.primary == SplitViewPanes.left)
    #expect(SplitViewPanes.primary == SplitViewPanes.top)

    #expect(SplitViewPanes.secondary == SplitViewPanes.right)
    #expect(SplitViewPanes.secondary == SplitViewPanes.bottom)
  }
}

@MainActor
@Suite("SplitViewFeature") struct SplitViewFeatureTests {

#if os(iOS)

  @Test func horizontalPreview() throws {
    let view = Group {
      SplitViewPreviews.horizontal
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
  }

  @Test func verticalPreview() throws {
    let view = Group {
      SplitViewPreviews.vertical
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
  }

  @Test func demoPreview() throws {
    let view = Group {
      SplitViewPreviews.demo
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
  }

#endif

}

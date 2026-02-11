import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BRHSplitView

@Suite("SplitViewConfiguration") struct SplitViewConfigurationTests {

  @Test func defaultBoundsSetup() throws {
    let svc = SplitViewConfiguration(orientation: .horizontal)
    #expect(svc.draggableRange == .normalized(0...1))
    #expect(svc.dragBounds(for: 123) == svc.draggableRange.bounds(for: 123))
  }

  @Test(
    "Bounds honors dragToHidePanes",
    arguments: [
      (SplitViewVisiblePanes.none, 0.3...0.8),
      (SplitViewVisiblePanes.primary, 0.0...0.8),
      (SplitViewVisiblePanes.secondary, 0.3...1.0),
      (SplitViewVisiblePanes.both, 0.0...1.0),
    ]
  )
  func boundsHonorsDragToHidePanes(run: (SplitViewVisiblePanes, ClosedRange<Double>)) throws {
    let svc = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.3...0.8),
      dragToHidePanes: run.0
    )
    #expect(svc.draggableRange == .normalized(0.3...0.8))
    #expect(svc.dragBounds(for: 123) == run.1)
    #expect(svc.dragLowerBound(for: 123) == run.1.lowerBound)
    #expect(svc.dragUpperBound(for: 123) == run.1.upperBound)
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
    #expect(SplitViewVisiblePanes.none.primary == false)
    #expect(SplitViewVisiblePanes.none.secondary == false)
    #expect(SplitViewVisiblePanes.none.both == false)

    #expect(SplitViewVisiblePanes.primary.primary == true)
    #expect(SplitViewVisiblePanes.primary.secondary == false)
    #expect(SplitViewVisiblePanes.primary.both == false)

    #expect(SplitViewVisiblePanes.secondary.primary == false)
    #expect(SplitViewVisiblePanes.secondary.secondary == true)
    #expect(SplitViewVisiblePanes.secondary.both == false)

    #expect(SplitViewVisiblePanes.both.primary == true)
    #expect(SplitViewVisiblePanes.both.secondary == true)
    #expect(SplitViewVisiblePanes.both.both == true)

    #expect(SplitViewVisiblePanes.primary == SplitViewVisiblePanes.left)
    #expect(SplitViewVisiblePanes.primary == SplitViewVisiblePanes.top)

    #expect(SplitViewVisiblePanes.secondary == SplitViewVisiblePanes.right)
    #expect(SplitViewVisiblePanes.secondary == SplitViewVisiblePanes.bottom)
  }
}

@MainActor
@Suite("SplitViewFeature") struct SplitViewFeatureTests {

  struct Run {
    let doubleClickToClose: SplitViewVisiblePanes
    let expected: SplitViewVisiblePanes
  }

  @Test("doubleClick does nothing")
  func testDoubleClickDoesNothing() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.3...0.6),
      dragToHidePanes: .none, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.doubleClicked(config: config))
  }

  @Test("doubleClick closes", arguments: [
    Run(doubleClickToClose: .primary, expected: .secondary),
    Run(doubleClickToClose: .secondary, expected: .primary),
    Run(doubleClickToClose: .both, expected: .primary)
  ])
  func testDoubleClickAction(run: Run) async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.3...0.6),
      dragToHidePanes: .none, doubleClickToClose: run.doubleClickToClose, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.doubleClicked(config: config)) {
      $0.panesVisible = run.expected
    }
    await store.receive(.delegate(.stateChanged(panesVisible: run.expected, position: 0.5)))
  }

  @Test("drag is constrained")
  func dragDoesNothing() async throws {
    let span = 100.0
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.3...0.6),
      dragToHidePanes: .none, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: 0.0))) {
      $0.initialPosition = 50.0
      $0.lastPosition = 0.5
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: -50.0))) {
      $0.position = config.draggableRange.lowerBound(for: span)
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: 100.0))) {
      $0.position = config.draggableRange.upperBound(for: span)
    }
    await store.send(.dragOnEnded(dragState: .init(config: config, span: span, change: 0.0))) {
      $0.initialPosition = nil
    }
    await store.receive(.delegate(.stateChanged(panesVisible: .both, position: 0.6)))
  }

  @Test("drag will hide secondary")
  func dragWillHideSecondary() async throws {
    let span = 100.0
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.3...0.6),
      dragToHidePanes: .secondary, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: 0.0))) {
      $0.initialPosition = 50.0
      $0.lastPosition = 0.5
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: -40.0))) {
      $0.lastPosition = 0.5
      $0.position = config.draggableRange.lowerBound(for: span)
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: 40.0))) {
      $0.position = 0.9
      $0.highlightPane = .secondary
    }
    await store.send(.dragOnEnded(dragState: .init(config: config, span: span, change: 0.0))) {
      $0.position = 0.5
      $0.panesVisible = .primary
      $0.highlightPane = .none
      $0.initialPosition = nil
    }
    await store.receive(.delegate(.stateChanged(panesVisible: .primary, position: 0.5)))
//    await store.receive(.delegate(.positionChanged(0.0)))
  }

  @Test("drag will hide primary")
  func dragWillHidePrimary() async throws {
    let span = 100.0
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.3...0.6),
      dragToHidePanes: .primary, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: 0.0))) {
      $0.initialPosition = 50.0
      $0.lastPosition = 0.5
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: 40.0))) {
      $0.lastPosition = 0.5
      $0.position = 0.6
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: -40.0))) {
      $0.position = 0.1
      $0.highlightPane = .primary
    }
    await store.send(.dragOnEnded(dragState: .init(config: config, span: span, change: 0.0))) {
      $0.position = 0.5
      $0.panesVisible = .secondary
      $0.highlightPane = .none
      $0.initialPosition = nil
    }
    await store.receive(.delegate(.stateChanged(panesVisible: .secondary, position: 0.5)))
  }

#if os(iOS)

  @Test func horizontalPreview() throws {
    let view = Group {
      SplitViewPreviews.horizontal
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)
    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func horizontalPreviewOnlyPrimary() throws {
    let view = Group {
      SplitView(
        store: Store(initialState: .init(panesVisible: .primary)) {
          SplitViewReducer()
        },
        primary: {
          Text("Hello")
        },
        divider: {
          MinimalDivider()
        },
        secondary: {
          Text("World!")
        }
      ).splitViewConfiguration(
        .init(
          orientation: .horizontal,
          draggableRange: .normalized(0.1...0.9)
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)
    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func horizontalPreviewOnlySecondary() throws {
    let view = Group {
      SplitView(
        store: Store(initialState: .init(panesVisible: .secondary)) {
          SplitViewReducer()
        },
        primary: {
          Text("Hello")
        },
        divider: {
          MinimalDivider()
        },
        secondary: {
          Text("World!")
        }
      ).splitViewConfiguration(
        .init(
          orientation: .horizontal,
          draggableRange: .normalized(0.1...0.9)
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)
    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func verticalPreview() throws {
    let view = Group {
      SplitViewPreviews.vertical
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)
    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func verticalPreviewOnlyPrimary() throws {
    let view = Group {
      SplitView(
        store: Store(initialState: .init(panesVisible: .primary)) {
          SplitViewReducer()
        },
        primary: {
          Text("Hello")
        },
        divider: {
          MinimalDivider()
        },
        secondary: {
          Text("World!")
        }
      ).splitViewConfiguration(
        .init(
          orientation: .vertical,
          draggableRange: .normalized(0.1...0.9)
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)
    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func verticalPreviewOnlySecondary() throws {
    let view = Group {
      SplitView(
        store: Store(initialState: .init(panesVisible: .secondary)) {
          SplitViewReducer()
        },
        primary: {
          Text("Hello")
        },
        divider: {
          MinimalDivider()
        },
        secondary: {
          Text("World!")
        }
      ).splitViewConfiguration(
        .init(
          orientation: .horizontal,
          draggableRange: .normalized(0.1...0.9)
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func verticalPreviewHighlightPrimary() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: .normalized(0.4...0.6),
      dragToHidePanes: .both
    )

    let store = Store(initialState: .init(panesVisible: .both)) {
      SplitViewReducer()
    }
    let view = Group {
      SplitView(store: store,
        primary: {
          Text("Hello")
        },
        divider: {
          MinimalDivider()
        },
        secondary: {
          Text("World!")
        }
      ).splitViewConfiguration(config)
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)
    store.send(.dragOnChanged(dragState: .init(config: config, span: 500, change: 0.0)))
    store.send(.dragOnChanged(dragState: .init(config: config, span: 500, change: -150.0)))
    #expect(store.highlightPane == .primary)

    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

  @Test func demoPreview() throws {
    let view = Group {
      SplitViewPreviews.demo
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    withSnapshotTesting(record: .failed) {
      TestSupport.assertSnapshot(matching: view, size: .init(width: 500, height: 500))
    }
  }

#endif

}

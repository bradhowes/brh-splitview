import ComposableArchitecture
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

  struct Run {
    let doubleClickToClose: SplitViewPanes
    let expected: SplitViewPanes
  }

  @Test("doubleClick does nothing")
  func testDoubleClickDoesNothing() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: 0.3...0.6,
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
      draggableRange: 0.3...0.6,
      dragToHidePanes: .none, doubleClickToClose: run.doubleClickToClose, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.doubleClicked(config: config)) {
      $0.panesVisible = run.expected
    }
    await store.receive(.delegate(.panesVisibilityChanged(run.expected)))
  }

  @Test("drag is constrained")
  func dragDoesNothing() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: 0.3...0.6,
      dragToHidePanes: .none, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: 0.0))) {
      $0.initialPosition = 50.0
      $0.lastPosition = 0.5
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: -50.0))) {
      $0.position = config.draggableRange.lowerBound
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: 100.0))) {
      $0.position = config.draggableRange.upperBound
    }
    await store.send(.dragOnEnded(config: config)) {
      $0.initialPosition = nil
    }
  }

  @Test("drag will hide secondary")
  func dragWillHideSecondary() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: 0.3...0.6,
      dragToHidePanes: .secondary, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: 0.0))) {
      $0.initialPosition = 50.0
      $0.lastPosition = 0.5
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: -40.0))) {
      $0.lastPosition = 0.5
      $0.position = config.draggableRange.lowerBound
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: 40.0))) {
      $0.position = 0.9
      $0.highlightPane = .secondary
    }
    await store.send(.dragOnEnded(config: config)) {
      $0.position = 0.5
      $0.panesVisible = .primary
      $0.highlightPane = .none
      $0.initialPosition = nil
    }
    await store.receive(.delegate(.panesVisibilityChanged(.primary)))
  }

  @Test("drag will hide primary")
  func dragWillHidePrimary() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: 0.3...0.6,
      dragToHidePanes: .primary, doubleClickToClose: .none, visibleDividerSpan: 4.0
    )
    let store = TestStore(initialState: SplitViewReducer.State()) { SplitViewReducer() }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: 0.0))) {
      $0.initialPosition = 50.0
      $0.lastPosition = 0.5
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: 40.0))) {
      $0.lastPosition = 0.5
      $0.position = 0.6
    }
    await store.send(.dragOnChanged(dragState: .init(config: config, span: 100, change: -40.0))) {
      $0.position = 0.1
      $0.highlightPane = .primary
    }
    await store.send(.dragOnEnded(config: config)) {
      $0.position = 0.5
      $0.panesVisible = .secondary
      $0.highlightPane = .none
      $0.initialPosition = nil
    }
    await store.receive(.delegate(.panesVisibilityChanged(.secondary)))
  }


#if os(iOS)

  @Test func horizontalPreview() throws {
    let view = Group {
      SplitViewPreviews.horizontal
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
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
          draggableRange: 0.1...0.9
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
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
          draggableRange: 0.1...0.9
        ))
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
          draggableRange: 0.1...0.9
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
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
          draggableRange: 0.1...0.9
        ))
    }.frame(width: 500, height: 500)
      .background(Color.white)
      .environment(\.colorScheme, ColorScheme.light)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
  }

  @Test func verticalPreviewHighlightPrimary() async throws {
    let config = SplitViewConfiguration(
      orientation: .horizontal,
      draggableRange: 0.4...0.6,
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

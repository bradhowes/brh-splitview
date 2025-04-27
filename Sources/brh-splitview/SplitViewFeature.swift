// Copyright © 2025 Brad Howes. All rights reserved.

import ComposableArchitecture
import SwiftUI

@Reducer
public struct SplitViewReducer {

  @ObservableState
  public struct State: Equatable {
    /// The currently visible child panes
    public var panesVisible: SplitViewPanes
    /// The normalized position of the divider [0.0-1.0] where 0.0 is all the way to the left/up, and 1.0 is all the
    /// way to the right/down
    public var position: Double
    /// Any child pane to blur while dragging to signal that the child pane will close if dragging is
    /// stopped at the current position.
    public var highlightPane: SplitViewPanes = []
    /// Initial position of a drag gesture
    @ObservationStateIgnored public var initialPosition: Double?
    /// The last position before the start of a drag gesture.
    @ObservationStateIgnored public var lastPosition: Double = .zero

    public init(
      panesVisible: SplitViewPanes = .both,
      initialPosition: Double = 0.5
    ) {
      self.panesVisible = panesVisible
      self.position = initialPosition
    }
  }

  public struct DragState: Equatable {
    let config: SplitViewConfiguration
    let span: Double
    let change: Double
  }

  public enum Action: Equatable {
    case delegate(Delegate)
    case doubleClicked(config: SplitViewConfiguration)
    case dragOnChanged(dragState: DragState)
    case dragOnEnded(config: SplitViewConfiguration)
    case updatePanesVisibility(SplitViewPanes)
  }

  @CasePathable
  public enum Delegate: Equatable {
    case panesVisibilityChanged(SplitViewPanes)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate: return .none
      case let .doubleClicked(config): return doubleClicked(&state, config: config)
      case let .dragOnChanged(dragState): return dragOnChanged(&state, dragState: dragState)
      case let .dragOnEnded(config): return dragOnEnded(&state, config: config)
      case let .updatePanesVisibility(visible): return updateVisiblePanes(&state, panes: visible)
      }
    }
  }

  private func doubleClicked(_ state: inout State, config: SplitViewConfiguration) -> Effect<Action> {
    if config.doubleClickToClose.contains(.secondary) {
      return updateVisiblePanes(&state, panes: .primary)
    } else if config.doubleClickToClose.contains(.primary) {
      return updateVisiblePanes(&state, panes: .secondary)
    }
    return .none
  }

  private func dragOnChanged(_ state: inout State, dragState: DragState) -> Effect<Action> {
    if let initialPosition = state.initialPosition {
      // Calculate new normalized position [0.0-1.0] of the divider
      let unconstrained = (initialPosition + dragState.change).normalize(in: 0...dragState.span)
      // Constrain the above so that it obeys the configured constraints
      let position = unconstrained.clamped(to: dragState.config.dragBounds)
      if position < dragState.config.draggableRange.lowerBound {
        // Highlight the primary pane will be closed if the drag ends
        state.highlightPane = .primary
      } else if position > dragState.config.draggableRange.upperBound {
        // Highlight the secondary pane will be closed if the drag ends
        state.highlightPane = .secondary
      } else {
        state.highlightPane = .none
      }
      state.position = position
    } else {
      state.lastPosition = state.position
      state.initialPosition = dragState.span * state.position
    }
    return .none
  }

  private func dragOnEnded(_ state: inout State, config: SplitViewConfiguration) -> Effect<Action> {
    state.initialPosition = nil
    state.highlightPane = []
    if state.position < config.draggableRange.lowerBound {
      return updatePosition(&state, position: state.lastPosition, panes: .secondary)
    } else if state.position > config.draggableRange.upperBound {
      return updatePosition(&state, position: state.lastPosition, panes: .primary)
    } else {
      return updatePosition(&state, position: state.position.clamped(to: config.draggableRange), panes: .both)
    }
  }

  private func updatePosition(_ state: inout State, position: Double, panes: SplitViewPanes) -> Effect<Action> {
    state.position = position
    return updateVisiblePanes(&state, panes: panes)
  }

  private func updateVisiblePanes(_ state: inout State, panes: SplitViewPanes) -> Effect<Action> {
    guard state.panesVisible != panes else { return .none }
    state.panesVisible = panes
    return .send(.delegate(.panesVisibilityChanged(panes)))
  }
}

/**
 Custom view that manages `primary` and a `secondary` views or "panes" separated by a divider view. The divider
 recognizes drag gestures to change the size of the managed views. It also supports a double-tap
 gesture that will close/hide one of the views when allowed in the `constraints` settings.
 */
public struct SplitView<P, D, S>: View where P: View, D: View, S: View {
  private let store: StoreOf<SplitViewReducer>
  private let primaryContent: () -> P
  private let secondaryContent: () -> S
  private let dividerContent: () -> D
  @Environment(\.splitViewConfiguration) private var config

  private var orientation: SplitViewOrientation { config.orientation }
  private var panesVisible: SplitViewPanes { store.panesVisible }
  private var highlightSide: SplitViewPanes { store.highlightPane }

  public init(
    store: StoreOf<SplitViewReducer>,
    @ViewBuilder primary: @escaping () -> P,
    @ViewBuilder divider: @escaping () -> D,
    @ViewBuilder secondary: @escaping () -> S
  ) {
    self.store = store
    self.primaryContent = primary
    self.secondaryContent = secondary
    self.dividerContent = divider
  }

  public var body: some View {
    let _ = Self._printChanges()
    GeometryReader { geometry in
      let size = geometry.size
      let width = size.width
      let height = size.height
      let span: Double = orientation.horizontal ? width : height
      let handleSpan: Double = config.visibleDividerSpan
      let handleSpan2: Double = handleSpan / 2
      let dividerPos = (store.position * span).clamped(to: 0...span)
      let primarySpan = (dividerPos - handleSpan2).clamped(to: 0...span)
      let primaryAndHandleSpan = primarySpan + handleSpan
      let secondarySpan = (span - primaryAndHandleSpan).clamped(to: 0...span)

      let primaryFrame: CGSize = orientation.horizontal
        ? .init(width: panesVisible.secondary ? primarySpan : span, height: height)
        : .init(width: width, height: panesVisible.secondary ? primarySpan : span)

      let primaryOffset: CGSize = orientation.horizontal
        ? .init(width: panesVisible.primary ? 0 : -primaryAndHandleSpan, height: 0)
        : .init(width: 0, height: panesVisible.primary ? 0 : -primaryAndHandleSpan)

      let secondaryFrame: CGSize = orientation.horizontal
        ? .init(width: panesVisible.primary ? secondarySpan : span, height: height)
        : .init(width: width, height: panesVisible.primary ? secondarySpan : span)

      let secondaryOffsetSpan = panesVisible.both ? primaryAndHandleSpan : panesVisible.primary ? span + handleSpan : 0
      let secondaryOffset: CGSize = orientation.horizontal
        ? .init(width: secondaryOffsetSpan, height: 0)
        : .init(width: 0, height: secondaryOffsetSpan)

      let dividerOffset = panesVisible.both ? dividerPos : panesVisible.primary ? span + handleSpan2 : -handleSpan2
      let dividerPt: CGPoint = orientation.horizontal
        ? .init(x: dividerOffset, y: height / 2)
        : .init(x: width / 2, y: dividerOffset)

      ZStack(alignment: .topLeading) {
        primaryContent()
          .zIndex(panesVisible.primary ? 0 : -1)
          .frame(width: primaryFrame.width, height: primaryFrame.height)
          .clipped()
          .blur(radius: highlightSide == .primary ? 3 : 0, opaque: false)
          .offset(primaryOffset)
          .allowsHitTesting(panesVisible.primary)

        secondaryContent()
          .zIndex(panesVisible.secondary ? 0 : -1)
          .frame(width: secondaryFrame.width, height: secondaryFrame.height)
          .clipped()
          .blur(radius: highlightSide == .secondary ? 3 : 0, opaque: false)
          .offset(secondaryOffset)
          .allowsHitTesting(panesVisible.secondary)

        dividerContent()
          .position(dividerPt)
          .zIndex(panesVisible.both ? 1 : -2)
          .onTapGesture(count: 2) {
            store.send(.doubleClicked(config: config))
          }
          .simultaneousGesture(
            drag(in: span, change: orientation.horizontal ? \.translation.width : \.translation.height)
          )
      }
      .frame(width: width, height: height)
      .clipped()
      .animation(.smooth, value: store.highlightPane)
      .animation(.smooth, value: store.panesVisible)
    }
  }
}

extension SplitView {

  private func drag(in span: Double, change: KeyPath<DragGesture.Value, CGFloat>) -> some Gesture {
    DragGesture(coordinateSpace: .global)
      .onChanged { gesture in
        store.send(.dragOnChanged(dragState: .init(config: config, span: span, change: gesture[keyPath: change])))
      }
      .onEnded { _ in
        store.send(.dragOnEnded(config: config))
      }
  }
}

private struct DemoHSplit: View {
  @State var store: StoreOf<SplitViewReducer>

  public init(store: StoreOf<SplitViewReducer>) {
    self.store = store
  }

  public var body: some View {
    SplitView(store: store) {
      VStack {
        button("Right", pane: .primary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.green)
    } divider: {
      HandleDivider(dividerColor: .black)  // DebugDivider()
    } secondary: {
      VStack {
        button("Left", pane: .secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.orange)
    }
  }

  private func button(_ side: String, pane: SplitViewPanes) -> some View {
    Button {
      store.send(.updatePanesVisibility(store.panesVisible.both ? pane : .both))
    } label: {
      Text(store.panesVisible.both ? "Hide \(side)" : "Show \(side)")
        .foregroundStyle(Color.blue)
    }
  }
}

private struct DemoVSplit: View {
  @State var store: StoreOf<SplitViewReducer>
  let inner: StoreOf<SplitViewReducer>

  public var body: some View {
    VStack {
      SplitView(store: store) {
        VStack {
          button("Bottom", pane: .primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mint)
      } divider: {
        HandleDivider(dividerColor: .black)  // DebugDivider()
      } secondary: {
        HStack {
          VStack {
            button("Top", pane: .secondary)
          }
          .contentShape(Rectangle())
          .padding()

          DemoHSplit(store: inner)
            .splitViewConfiguration(
              .init(
                orientation: .horizontal,
                draggableRange: 0.3...0.7,
                dragToHidePanes: .both,
                doubleClickToClose: .left,
                visibleDividerSpan: 4
              ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brown)
      }.splitViewConfiguration(
        .init(
          orientation: .vertical,
          draggableRange: 0.3...0.7,
          dragToHidePanes: .bottom,
          doubleClickToClose: .bottom,
          visibleDividerSpan: 4
        ))
      // Collection of buttons that toggles pane visibility and shows current state.
      HStack {
        Button {
          store.send(.updatePanesVisibility(store.panesVisible.both ? .secondary : .both))
        } label: {
          Text("Top")
            .foregroundStyle(store.panesVisible.primary ? Color.accentColor : Color.orange)
            .animation(.smooth, value: store.panesVisible)
        }
        Button {
          store.send(.updatePanesVisibility(store.panesVisible.both ? .primary : .both))
        } label: {
          Text("Bottom")
            .foregroundStyle(store.panesVisible.secondary ? Color.accentColor : Color.orange)
            .animation(.smooth, value: store.panesVisible)
        }
        Button {
          inner.send(.updatePanesVisibility(inner.panesVisible.both ? .secondary : .both))
        } label: {
          Text("Left")
            .foregroundStyle(inner.panesVisible.primary ? Color.accentColor : Color.orange)
            .animation(.smooth, value: store.panesVisible)
        }
        Button {
          inner.send(.updatePanesVisibility(inner.panesVisible.both ? .primary : .both))
        } label: {
          Text("Right")
            .foregroundStyle(inner.panesVisible.secondary ? Color.accentColor : Color.orange)
            .animation(.smooth, value: store.panesVisible)
        }
      }.padding([.bottom], 8)
    }
  }

  private func button(_ side: String, pane: SplitViewPanes) -> some View {
    Button {
      store.send(.updatePanesVisibility(store.panesVisible.both ? pane : .both))
    } label: {
      Text(store.panesVisible.both ? "Hide \(side)" : "Show \(side)")
        .foregroundStyle(Color.blue)
    }
  }
}

internal struct SplitViewPreviews {

  @MainActor
  static var horizontal: some View {
    SplitView(
      store: Store(initialState: .init()) {
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
        draggableRange: 0.3...0.7,
        dragToHidePanes: .both
      ))
  }

  @MainActor
  static var vertical: some View {
    SplitView(
      store: Store(initialState: .init()) {
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
  }

  @MainActor
  static var demo: some View {
    DemoVSplit(
      store: Store(initialState: .init()) { SplitViewReducer() },
      inner: Store(initialState: .init()) { SplitViewReducer() }
    )
  }
}

struct SplitView_Previews: PreviewProvider {
  static var previews: some View {
    SplitViewPreviews.horizontal
    SplitViewPreviews.vertical
    SplitViewPreviews.demo
  }
}

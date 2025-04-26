// Copyright © 2025 Brad Howes. All rights reserved.

import ComposableArchitecture
import SwiftUI

@Reducer
public struct SplitViewReducer {

  @ObservableState
  public struct State: Equatable {
    /// The currently visible child panes
    public var panesVisible: SplitViewPanes
    /// The normalized position of the divider [0.0-1.0]
    public var position: Double
    /// Any child pane to blur while dragging to signal that the child pane will close if dragging is
    /// stopped at the current position.
    public var highlightPane: SplitViewPanes = []
    // Drag-gesture state. Unable to move into a @GestureState struct since its lifetime is not long enough to be
    // useful.
    @ObservationStateIgnored public var initialPosition: Double?
    @ObservationStateIgnored public var lastPosition: Double = .zero

    public init(
      panesVisible: SplitViewPanes = .both,
      initialPosition: Double = 0.5
    ) {
      self.panesVisible = panesVisible
      self.position = initialPosition
    }
  }

  public enum Action: Equatable {
    case delegate(Delegate)
    case doubleClicked(config: SplitViewConfiguration)
    case dragOnChanged(config: SplitViewConfiguration, gesture: DragGesture.Value, span: Double,
                       change: KeyPath<DragGesture.Value, CGFloat>)
    case dragOnEnded(config: SplitViewConfiguration)
    case updatePanesVisibility(SplitViewPanes)
  }

  @CasePathable
  public enum Delegate: Equatable {
    case panesVisibilityChanged(SplitViewPanes)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action  in
      switch action {
      case .delegate: return .none
      case let .doubleClicked(config): return doubleClicked(&state, config: config)
      case let .dragOnChanged(config, gesture, span, keyPath): return dragOnChanged(
        &state, config: config, gesture: gesture, span: span, change: keyPath
      )
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

  private func dragBegin(_ state: inout State, span: Double) -> Effect<Action> {
    state.lastPosition = state.position
    state.initialPosition = span * state.position
    return .none
  }

  private func dragEnd(_ state: inout State, position: Double, visible: SplitViewPanes) -> Effect<Action> {
    state.initialPosition = nil
    state.highlightPane = []
    state.position = position
    return updateVisiblePanes(&state, panes: visible)
  }

  private func dragMove(_ state: inout State, position: Double, willHide: SplitViewPanes) -> Effect<Action> {
    state.position = position
    state.highlightPane = willHide
    return .none
  }

  private func dragOnChanged(
    _ state: inout State,
    config: SplitViewConfiguration,
    gesture: DragGesture.Value,
    span: Double,
    change: KeyPath<DragGesture.Value, CGFloat>
  ) -> Effect<Action> {
    if let initialPosition = state.initialPosition {
      // Calculate new normalized position [0.0-1.0] of the divider
      let unconstrained = (initialPosition + gesture[keyPath: change]).clamped(to: 0...span) / span
      // Constrain the above so that it obeys the configured constraints
      let position = unconstrained.clamped(to: config.dragBounds)
      if position < config.draggableRange.lowerBound {
        // Highlight the primary pane will be closed if the drag ends
        state.highlightPane = .primary
      } else if position > config.draggableRange.upperBound {
        // Highlight the secondary pane will be closed if the drag ends
        state.highlightPane = .secondary
      } else {
        state.highlightPane = .none
      }
      state.position = position
    } else {
      state.lastPosition = state.position
      state.initialPosition = span * state.position
    }
    return .none
  }

  private func dragOnEnded(_ state: inout State, config: SplitViewConfiguration) -> Effect<Action> {
    state.initialPosition = nil
    state.highlightPane = []
    if state.position < config.draggableRange.lowerBound {
      // Dragged below the draggableRange so close the primary child view pane
      state.position = state.lastPosition
      return updateVisiblePanes(&state, panes: .secondary)
    } else if state.position > config.draggableRange.upperBound {
      // Dragged above the draggableRange so close the secondary child view pane
      state.position = state.lastPosition
      return updateVisiblePanes(&state, panes: .primary)
    } else {
      // Not closing anything -- just update the new divider position.
      state.position = state.position.clamped(to: config.draggableRange)
      return .none
    }
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
    @ViewBuilder primary: @escaping ()-> P,
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
      let primarySpan = dividerPos - handleSpan2
      let primaryAndHandleSpan = primarySpan + handleSpan
      let secondarySpan = span - primaryAndHandleSpan

      let primaryFrame: CGSize = orientation.horizontal
      ? .init(width: panesVisible.secondary ? primarySpan : span, height: height)
      : .init(width: width, height: panesVisible.secondary ? primarySpan : span)

      let primaryOffset: CGSize = orientation.horizontal
      ? .init(width: panesVisible.primary ? 0 : -primaryAndHandleSpan, height: 0)
      : .init(width: 0, height: panesVisible.primary ? 0 : -primaryAndHandleSpan)

      let secondaryFrame: CGSize = orientation.horizontal
      ? .init(width: panesVisible.primary ? secondarySpan : span, height: height)
      : .init(width: width, height: panesVisible.primary ? secondarySpan : span)

      let secondaryOffsetSpan = panesVisible.both ? primaryAndHandleSpan : (panesVisible.primary ? span + handleSpan: 0)
      let secondaryOffset: CGSize = orientation.horizontal
      ? .init(width: secondaryOffsetSpan, height: 0)
      : .init(width: 0, height: secondaryOffsetSpan)

      let dividerOffset = (panesVisible.both ? dividerPos : (panesVisible.primary ? span + handleSpan2 : -handleSpan2))
      let dividerPt: CGPoint = orientation.horizontal
      ? .init(x: dividerOffset, y: height / 2)
      : .init(x: width / 2, y: dividerOffset)

      ZStack(alignment: .topLeading) {
        primaryContent()
          .zIndex(panesVisible.primary ? 0 : -1)
          .frame(width: primaryFrame.width, height: primaryFrame.height)
          .blur(radius: highlightSide == .primary ? 3 : 0, opaque: false)
          .offset(primaryOffset)
          .allowsHitTesting(panesVisible.primary)

        secondaryContent()
          .zIndex(panesVisible.secondary ? 0 : -1)
          .frame(width: secondaryFrame.width, height: secondaryFrame.height)
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
      .animation(.smooth, value: store.panesVisible)
    }
  }
}

extension SplitView {

  private func drag(in span: Double, change: KeyPath<DragGesture.Value, CGFloat>) -> some Gesture {
    return DragGesture(coordinateSpace: .global)
      .onChanged { gesture in
        store.send(.dragOnChanged(config: config, gesture: gesture, span: span, change: change))
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
      HandleDivider(dividerColor: .black) // DebugDivider()
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
        HandleDivider(dividerColor: .black) // DebugDivider()
      } secondary: {
        HStack {
          VStack {
            button("Top", pane: .secondary)
          }
          .contentShape(Rectangle())
          .padding()

          DemoHSplit(store: inner)
            .splitViewConfiguration(.init(
              orientation: .horizontal,
              draggableRange: 0.3...0.7,
              dragToHidePanes: .both,
              doubleClickToClose: .left,
              visibleDividerSpan: 4
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brown)
      }.splitViewConfiguration(.init(
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
    SplitView(store: Store(initialState: .init()) {
      SplitViewReducer()
    }, primary: {
      Text("Hello")
    }, divider: {
      MinimalDivider()
    }, secondary: {
      Text("World!")
    }).splitViewConfiguration(.init(
      orientation: .horizontal,
      draggableRange: 0.1...0.9
    ))
  }

  @MainActor
  static var vertical: some View {
    SplitView(store: Store(initialState: .init()) {
      SplitViewReducer()
    }, primary: {
      Text("Hello")
    }, divider: {
      MinimalDivider()
    }, secondary: {
      Text("World!")
    }).splitViewConfiguration(.init(
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

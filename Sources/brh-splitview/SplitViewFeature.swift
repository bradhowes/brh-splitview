// Copyright © 2025 Brad Howes. All rights reserved.

import ComposableArchitecture
import SwiftUI

@Reducer
public struct SplitViewReducer {

  @ObservableState
  public struct State: Equatable {
    public var panesVisible: SplitViewPanes
    public var position: Double

    // Drag-gesture state. Unable to move into a @GestureState struct since its lifetime is not long enough to be
    // useful.
    public var highlightPane: SplitViewPanes = []
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
    case dragBegin(Double)
    case dragMove(Double, SplitViewPanes)
    case dragEnd(Double, SplitViewPanes)
    case updatePanesVisibility(SplitViewPanes)
    case delegate(Delegate)
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
      case let .dragBegin(span): return dragBegin(&state, span: span)
      case let .dragEnd(position, visible): return dragEnd(&state, position: position, visible: visible)
      case let .dragMove(position, willHide): return dragMove(&state, position: position, willHide: willHide)
      case .updatePanesVisibility(let visible): return updateVisiblePanes(&state, panes: visible)
      }
    }
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
            if config.dragToHidePanes.contains(.primary) {
              store.send(.updatePanesVisibility(.secondary))
            } else if config.dragToHidePanes.contains(.secondary) {
              store.send(.updatePanesVisibility(.primary))
            }
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
        if let initialPosition = store.initialPosition {
          let unconstrained = (initialPosition + gesture[keyPath: change]).clamped(to: 0...span) / span
          let position = unconstrained.clamped(to: lowerBound...upperBound)
          if position < minPrimarySpan {
            store.send(.dragMove(position, .primary))
          } else if position > maxSecondarySpan {
            store.send(.dragMove(position, .secondary))
          } else {
            store.send(.dragMove(position, .none))
          }
        } else {
          store.send(.dragBegin(span))
        }
      }
      .onEnded { gesture in
        if store.position < minPrimarySpan {
          store.send(.dragEnd(store.lastPosition, .secondary))
        } else if store.position > maxSecondarySpan {
          store.send(.dragEnd(store.lastPosition, .primary))
        } else {
          store.send(.dragEnd(store.position.clamped(to: minPrimarySpan...maxSecondarySpan), .both))
        }
      }
  }

  private var minPrimarySpan: Double { config.minimumPrimaryFraction }
  private var maxSecondarySpan: Double { 1.0 - config.minimumSecondaryFraction }
  private var lowerBound: Double { config.dragToHidePanes.contains(.primary) ? 0.0 : minPrimarySpan }
  private var upperBound: Double { config.dragToHidePanes.contains(.secondary) ? 1.0 : maxSecondarySpan }
}

private struct DemoHSplit: View {
  @State var store: StoreOf<SplitViewReducer>

  public init(store: StoreOf<SplitViewReducer>) {
    self.store = store
  }

  public var body: some View {
    SplitView(store: store) {
      VStack {
        Button(store.panesVisible.both ? "Hide Right" : "Show Right") {
          store.send(.updatePanesVisibility(store.panesVisible.both ? .primary : .both))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.green)
    } divider: {
      HandleDivider() // DebugDivider()
    } secondary: {
      VStack {
        Button(store.panesVisible.both ? "Hide Left" : "Show Left") {
          store.send(.updatePanesVisibility(store.panesVisible.both ? .secondary : .both))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.orange)
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
          Button(store.panesVisible.both ? "Hide Bottom" : "Show Bottom") {
            store.send(.updatePanesVisibility(store.panesVisible.both ? .primary : .both))
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mint)
      } divider: {
        HandleDivider() // DebugDivider()
      } secondary: {
        HStack {
          VStack {
            Button(store.panesVisible.both ? "Hide Top" : "Show Top") {
              store.send(.updatePanesVisibility(store.panesVisible.both ? .secondary : .both))
            }
          }.contentShape(Rectangle())
          DemoHSplit(store: inner)
            .splitViewConfiguration(.init(
              orientation: .horizontal,
              minimumPrimaryFraction: 0.3,
              minimumSecondaryFraction: 0.3,
              dragToHidePanes: .both,
              visibleDividerSpan: 4
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.teal)
      }.splitViewConfiguration(.init(
        orientation: .vertical,
        minimumPrimaryFraction: 0.3,
        minimumSecondaryFraction: 0.3,
        dragToHidePanes: .bottom,
        visibleDividerSpan: 4
      ))
      HStack {
        Button {
          store.send(.updatePanesVisibility(store.panesVisible.both ? .secondary : .both))
        } label: {
          Text("Top")
            .foregroundStyle(store.panesVisible.primary ? Color.orange : Color.accentColor)
            .animation(.smooth, value: store.panesVisible)
        }
        Button {
          store.send(.updatePanesVisibility(store.panesVisible.both ? .primary : .both))
        } label: {
          Text("Bottom")
            .foregroundStyle(store.panesVisible.secondary ? Color.orange : Color.accentColor)
            .animation(.smooth, value: store.panesVisible)
        }
        Button {
          inner.send(.updatePanesVisibility(inner.panesVisible.both ? .secondary : .both))
        } label: {
          Text("Left")
            .foregroundStyle(inner.panesVisible.primary ? Color.orange : Color.accentColor)
            .animation(.smooth, value: store.panesVisible)
        }
        Button {
          inner.send(.updatePanesVisibility(inner.panesVisible.both ? .primary : .both))
        } label: {
          Text("Right")
            .foregroundStyle(inner.panesVisible.secondary ? Color.orange : Color.accentColor)
            .animation(.smooth, value: store.panesVisible)
        }
      }
    }
  }
}

struct SplitView_Previews: PreviewProvider {
  static var previews: some View {
    SplitView(store: Store(initialState: .init()) {
      SplitViewReducer()
    }, primary: {
      Text("Hello")
    }, divider: {
      MinimalDivider()
    }, secondary: {
      Text("World!")
    })
    .environment(\.splitViewConfiguration, .init())
    SplitView(store: Store(initialState: .init()) {
      SplitViewReducer()
    }, primary: {
      Text("Hello")
    }, divider: {
      MinimalDivider()
    }, secondary: {
      Text("World!")
    })
    .environment(\.splitViewConfiguration, .init(orientation: .vertical))
    DemoVSplit(
      store: Store(initialState: .init()) { SplitViewReducer() },
      inner: Store(initialState: .init()) { SplitViewReducer() }
    )
  }
}

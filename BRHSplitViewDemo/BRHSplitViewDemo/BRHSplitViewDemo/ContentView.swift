import BRHSplitView
import ComposableArchitecture
import SwiftUI

struct ContentView: View {
  var body: some View {
    DemoVSplit(
      store: Store(initialState: .init()) { SplitViewReducer() },
      inner: Store(initialState: .init()) { SplitViewReducer() }
    )
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

#Preview {
  ContentView()
}

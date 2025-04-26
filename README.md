[![CI](https://github.com/bradhowes/brh-splitview/workflows/CI/badge.svg)](.github/workflows/CI.yml)
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/09b95180719ff3c213d0d57a87f5202e/raw/brh-splitview-coverage.json)](.github/workflows/CI.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fbrh-splitview%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/bradhowes/brh-splitview)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fbrh-splitview%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/bradhowes/brh-splitview)

# brh-splitview

This is a custom SwiftUI view that manages the layout of two child views ("panes") by the position of a third 
"divider" view. Uses the excellent 
[Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) for Swift by
[Point-Free](https://www.pointfree.co) for handling state.

The three views are provided to a [SplitView]() instance via SwiftUI @ViewBuilder arguments:

```
public var body: some View {
  SplitView(store: store) {
    Text("Hello")
  } divider: {
    HandleDivider()
  } secondary: {
    Text("World")
  }.splitViewConfiguration(.init())
}
```

Here is a demo view that contains a vertical split view with the lower child pane holding a horizontal split view. The
split view configurations enable dragging to close a child pane -- the horizontal split view allows it for both child
panes, while the vertical orientation only allows it for the lower child pane. Here is the macOS rendering:

![](media/macOS.gif?raw=true)

And below shows the iOSrendering:

![](media/iOS.gif?raw=true)

# Configuration


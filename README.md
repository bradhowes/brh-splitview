[![CI](https://github.com/bradhowes/brh-splitview/workflows/CI/badge.svg)](.github/workflows/CI.yml)
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/16c85b76b7ca6fa55902ac6661e3bfde/raw/brh-splitview-coverage.json)](.github/workflows/CI.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fbrh-splitview%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/bradhowes/brh-splitview)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fbrh-splitview%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/bradhowes/brh-splitview)

# brh-splitview

This is a custom SwiftUI view that manages the layout of two child views ("panes") by the position of a third 
"divider" view. Uses the [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 
(TCA) by [Point-Free](https://www.pointfree.co) for handling state.

The three views are provided to a [SplitView](Sources/brh-splitview/SplitViewFeature.swift) instance via SwiftUI
@ViewBuilder arguments:

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

Included in this repo is a [demo app](BRHSplitViewDemo/BRHSplitViewDemo) that runs on macOS and iOS. The app
contains a vertical split view with the lower child pane holding a horizontal split view. The
split view configurations enable dragging to close a child pane -- the horizontal split view allows it for both child
panes, while the vertical orientation only allows it for the lower child pane. Inside each child view is a button that
controls visibility of its sibling. Below is an animated image of the macOS version:

![](media/macOS.gif?raw=true)

And below shows the app running on an iOS device:

<img src="media/iOS.gif?raw=true" width="300">

# Features

* Divider and child views are any SwiftUI `@ViewBuilder` values you provide to the `SplitView` view constructor.
* Inject custom configurations through the `.splitViewConfiguration` View modifier.
* Dividers can close either or both child views if you drag the divider over a certain amount of the child view pane.
* Blurs the child view pane that will be closed.
* Double-clicking on a divider can close a view as well.
* State of child pane visibility is available for tracking and manipulation in the SplitView's TCA store.

# Configuration

The [SplitViewConfiguration](Sources/brh-splitview/SplitViewConfiguration.swift) struct controls the layout and 
behavior of the views. It currently has the following attributes:

* orientation -- the layout of the child views (`.horizontal` or `.vertical`)
* draggableRange (ClosedRange) -- the range that the divider can be moved over. If `dragToHidePanes` (below) is
empty then dragging is limited to this. Otherwise, dragging outside of this range will result in closing a
child pane.
* dragToHidePanes ([SplitViewPanes](Sources/brh-splitview/SplitViewPanes.swift)) -- which child panes can be closed by 
  dragging into their minimum area. By default none are. Affects the behavior of the `draggableRange` above.
* doubleClickToClose ([SplitViewPanes](Sources/brh-splitview/SplitViewPanes.swift)) -- which child pane to close when
  the divider is double-tapped/clicked. By default none are.
* visibleDividerSpan (Double) -- the width or height of the divider. Dividers can draw outside of this span, including 
  defining a bigger area for touch tracking.

# Divider Examples

The source currently contains three divider views:

* [Debug](Sources/brh-splitview/Dividers/Debug.swift) -- used during development with separate overlapping regions for the divider 
  and the hit tracking area.
* [Minimal](Sources/brh-splitview/Dividers/Minimal.swift) -- just draws a solid line. The line width and the color are 
  configurable.
* [Handle](Sources/brh-splitview/Dividers/Handle.swift) -- draws a solid line as well as a handle that serves as a 
  visual hint that the divider can be dragged by the user.

# Alternatives

In another project I was originally using [SplitView](https://github.com/stevengharris/SplitView) by
[Steve Harris](https://github.com/stevengharris) which is very nice, but I opted to write my own after having some
difficulty integrating it into my app that is based on TCA. My version adopts many of the same features, but it does
have a hard dependency on TCA, so consider Steve's implementation if you are looking for a SwifUI-only version.


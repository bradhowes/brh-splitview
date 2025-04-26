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
    HandleDivider(for: .vertical, constraints: store.constraints)
  } secondary: {
    Text("World")
  }
}
```

![](Simple_iOS.gif?raw=true)

And below shows rendering on macOS:

![](Simple_macos.gif?raw=true)

# Configuration


# Demo App

There is a simple demonstration application that runs on both macOS and iOS which shows the linkage via AUv3 parameters
between AUv3 controls and AppKit/UIKit controls -- changes to one control cause a change in a specific AUParameter, 
which is then seen by the other control. To build and run, open the Xcode project file in the [Demo](Demo) 
folder. Make sure that the AUv3Controls package [Package.swift](Package.swift) file is not current open or else the demo
will fail to build. 


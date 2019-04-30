# FlowKit

FlowKit offers a data-driven declarative approach for building fast & flexible list in iOS.

|  	| Features Highlights 	|
|---	|---------------------------------------------------------------------------------	|
| 🕺 	| No more delegates & datasource. Just a fully type-safe declarative content approach. 	|
| 🧩 	| Better architecture to reuse components e decuple data from UI. 	|
| 🌈 	| Animate content changes automatically, no `reloadData`/`performBatchUpdates`. 	|
| 🚀 	| Blazing fast diff algorithm based upon [DifferenceKit](https://github.com/ra1028/DifferenceKit) 	|
| 🧬 	| It uses standard UIKit components at its core. No magic! 	|
| 💎 	| (COMING SOON) Support for scrollable declarative/fully customizable stack view. 	|
| 🐦 	| Fully made in Swift from Swift ❥ Lovers 	|

FlowKit was created and maintaned by [Daniele Margutti](https://github.com/malcommac) - My home site [www.danielemargutti.com](https://www.danielemargutti.com).

## Requirements

- Xcode 9.0+
- iOS 8.0+
- Swift 5+

## Installation

The preferred installation method is with CocoaPods. Add the following to your Podfile:

`pod 'FlowKit', '~> 1.0'`

## What you can achieve

The following code is a just a silly example of what you can achieve using FlowKit:

```swift
```

## Documentation

- Main Concepts

### Main Concepts

All the FlowKit's SDK is based upon two concepts: the **director** and the **adapter**.

The **director** is the class which manage the content of a list, keep in sync data with UI and offers all the methods and properties to manage it. When you need to add, move or remove a section or a cell, change the header or a footer you find all the methods and properties in this class.
A director instance can be associated with only one list (table or collection); once a director is assigned to a list it become the datasource and delegate of the object.

The following directors are available:

- `TableDirector` used to manage `UITableView` instances
- `CollectionDirector` and `FlowCollectionDirector` used to manage `UICollectionView` with custom or `UICollectionViewFlowLayout` layout.


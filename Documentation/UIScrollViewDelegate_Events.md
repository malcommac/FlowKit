# UIScrollViewDelegate

The following document describe the events available for FlowKit when you are using it to manage `UIScrollViewDelegate` events both available for `UITableView` and `UICollectionView`.

The following events are available from director's `.onScroll` property both for `TableDirector` and `CollectionDirector`.

### Events

- `didScroll: ((UIScrollView) -> Void)`
- `willBeginDragging: ((UIScrollView) -> Void)`
- `willEndDragging: ((_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetOffset: UnsafeMutablePointer<CGPoint>) -> Void)`
- `endDragging: ((_ scrollView: UIScrollView, _ willDecelerate: Bool) -> Void)`
- `shouldScrollToTop: ((UIScrollView) -> Bool)`
- `didScrollToTop: ((UIScrollView) -> Void)`
- `willBeginDecelerating: ((UIScrollView) -> Void)`
- `endDecelerating: ((UIScrollView) -> Void)`
- `viewForZooming: ((UIScrollView) -> UIView?)`l
- `willBeginZooming: ((_ scrollView: UIScrollView, _ view: UIView?) -> Void)`
- `endZooming: ((_ scrollView: UIScrollView, _ view: UIView?, _ scale: CGFloat) -> Void)`
- `didZoom: ((UIScrollView) -> Void)`
- `endScrollingAnimation: ((UIScrollView) -> Void)`
- `didChangeAdjustedContentInset: ((UIScrollView) -> Void)`

### Example

```swift
tableView.director.didDidScroll = { scrollView in
	print("Scrolling at x:\(scrollView.contentOffset.x), y:\(scrollView.contentOffset.y)")
}
```
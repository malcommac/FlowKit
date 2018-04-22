# Collection Events

The following document describe the events available for FlowKit when you are using it to manage `UICollectionView`.

Events are available at 3 different levels:

- **Director Events**: all general purpose events which are not strictly related to the single model's management. It includes general header/footer and scrollview delegate events.
- **Adapter Events**: each adapter manage a single pair of Model (`M: ModelProtocol`) and View (`C: CellProtocol`). It will receive all events related to single model instance configuration (dequeue, item size etc.).
- **Section Events**: `CollectionSectionView` instances manage custom view header/footer of a specific `CollectionSection`. It will receive events about dequeue, view's visibility.

## Contents

- `CollectionDirector`
	- Events
	- Received Context
	- Example

- `TableAdapter`
	- Events
	- Received Context
	- Example

- `TableSectionView`
	- Events
	- Received Context
	- Example


--

## `CollectionDirector ` Events

The following events are available from `CollectionDirector`'s `.on` property.

### Events

- `layoutDidChange: ((_ old: UICollectionViewLayout, _ new: UICollectionViewLayout) -> UICollectionViewTransitionLayout?)`
- `targetOffset: ((_ proposedContentOffset: CGPoint) -> CGPoint)`
- `moveItemPath: ((_ originalIndexPath: IndexPath, _ proposedIndexPath: IndexPath) -> IndexPath)`
- `shouldUpdateFocus: ((_ context: UICollectionViewFocusUpdateContext) -> Bool)`
- `didUpdateFocus: ((_ context: UICollectionViewFocusUpdateContext, _ coordinator: UIFocusAnimationCoordinator) -> Void)`
- `willDisplayHeader : ((HeaderFooterEvent) -> Void)`
- `willDisplayFooter : ((HeaderFooterEvent) -> Void)`
- `endDisplayHeader : ((HeaderFooterEvent) -> Void)`
- `endDisplayFooter : ((HeaderFooterEvent) -> Void)`

### Received Context

Some events will receive
`HeaderFooterEvent `is just a typealias which contains the relevant information of the header/footer.

`HeaderFooterEvent = (view: UIView, section: Int, table: UITableView)`

### Example

```swift
collectionView.director.on.willDisplayHeader = { ctx in
	print("Will display header for section \(ctx.section)")
}
```

## `CollectionAdapter ` Events

The following properties are used to manage the appearance and the behaviour for a pair of <model,cell> registered into the collection.
Each event will receive a `Context<M,C>` which contains a type safe instance of the involved model and (if available) cell.

### Events

The following events are reachable from `TableAdapter `'s `.on` property.

- `dequeue: ((EventContext) -> Void)`
- `shouldSelect: ((EventContext) -> Bool)`
- `shouldDeselect: ((EventContext) -> Bool)`
- `didSelect: ((EventContext) -> Void)`
- `didDeselect: ((EventContext) -> Void)`
- `didHighlight: ((EventContext) -> Void)`
- `didUnhighlight: ((EventContext) -> Void)`
- `shouldHighlight: ((EventContext) -> Bool)`
- `willDisplay: ((_ cell: C, _ path: IndexPath) -> Void)`
- `endDisplay: ((_ cell: C, _ path: IndexPath) -> Void)`
- `shouldShowEditMenu: ((EventContext) -> Bool)`
- `canPerformEditAction: ((EventContext) -> Bool)`
- `performEditAction: ((_ ctx: EventContext, _ selector: Selector, _ sender: Any?) -> Void)`
- `canFocus: ((EventContext) -> Bool)`
- `itemSize: ((EventContext) -> CGSize)`
- `prefetch: ((_ items: [M], _ paths: [IndexPath], _ collection: UICollectionView) -> Void)`
- `cancelPrefetch: ((_ items: [M], _ paths: [IndexPath], _ collection: UICollectionView) -> Void)`
- `shouldSpringLoad: ((EventContext) -> Bool)`

### Received Context

`EventContext` is a typealias for Adapter's `Context<M,C>` with `M` is the `ModelProtocol` instance managed by the table and `C` is `CellProtocol` instance used to represent data.

The following properties are available:

- `indexPath: IndexPath`: target model's index path
- `model: M`: type-safe instance of the model
- `cell: C`: type-safe instance of the cell
- `collection: UICollectionView`: parent collection view
- `collectionSize: CGSize`: parent collection view's size

### Example

```swift
let contactAdapter = CollectionAdapter<Contact,CellContact>()

// intercept tap
contactAdapter.on.tap = { ctx in
	print("User tapped on \(ctx.model.fullName)")
	return .deselectAnimated
}

// dequeue event, used to configure the UI of the cell
contactAdapter.on.dequeue = { ctx in
	ctx.cell?.labelName?.text = ctx.model.firstName
	ctx.cell?.labelLastName?.text = ctx.model.lastName
}
```

## `CollectionSectionView ` events

The following events are received from single instances of `headerView`/`footerView` of a `TableSection` instance and are related to header/footer events.

### Events

The following events are available from `TableSectionView `'s `.on` property.

**`referenceSize` event is required.**

- `dequeue: ((EventContext) -> Void)`
- `referenceSize: ((EventContext) -> CGSize)`
- `didDisplay: ((EventContext) -> Void)`
- `endDisplay: ((EventContext) -> Void)`
- `willDisplay: ((EventContext) -> Void)`

### Example

```swift
let header = CollectionSectionView<CollectionExampleHeaderView>()
header.on.referenceSize = { ctx in
	return CGSize(width: ctx.collectionViewSize.width, height: 50)
}
header.on.dequeue = { ctx in
	ctx.view?.titleLabel?.text = "\(articles.count) Articles"
}

let section = CollectionSection(headerView: header, models: articles)
```

### Received Context

Where `Context<T>` is a structure which contains the following properties of the section view instance:

- `type: SectionType`: type of view (`footer` or `header`)
- `section: Int`: section of the item
- `view: T`: type safe instance of th header/footer
- `collection: UICollectionView`: parent collection view
- `collectionSize: CGSize`: parent collection view's size
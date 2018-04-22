# Table Events

The following document describe the events available for FlowKit when you are using it to manage `UITableView`.

Events are available at 3 different levels:

- **Director Events**: all general purpose events which are not strictly related to the single model's management. It includes general header/footer and scrollview delegate events.
- **Adapter Events**: each adapter manage a single pair of Model (`M: ModelProtocol`) and View (`C: CellProtocol`). It will receive all events related to single model instance configuration (dequeue, item size etc.).
- **Section Events**: `TableSectionView` instances manage custom view header/footer of a specific `TableSection`. It will receive events about dequeue, view's visibility.

## Contents

- `TableDirector`
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

## `TableDirector` Events

The following events are available from `TableDirector `'s `.on` property.

### Events

- `sectionForSectionIndex: ((_ title: String, _ index: Int) -> Int)` (name of the section is read automatically from `indexTitle` property of the section)
- `willDisplayHeader: ((HeaderFooterEvent) -> Void)`
- `willDisplayFooter: ((HeaderFooterEvent) -> Void)`
- `endDisplayHeader: ((HeaderFooterEvent) -> Void)`
- `endDisplayFooter: ((HeaderFooterEvent) -> Void)`

### Received Context

where `HeaderFooterEvent` is just a typealias which contains the relevant information of the header/footer.

`HeaderFooterEvent = (view: UIView, section: Int, table: UITableView)`

### Example

```swift
tableView.director.on.willDisplayHeader = { ctx in
	print("Will display header for section \(ctx.section)")
}
```

## `TableAdapter` Events

The following properties are used to manage the appearance and the behaviour for a pair of <model,cell> registered into the table.
Each event will receive a `Context<M,C>` which contains a type safe instance of the involved model and (if available) cell.

### Events

The following events are reachable from `TableAdapter `'s `.on` property.

- `dequeue : ((EventContext) -> (Void))`
- `canEdit: ((EventContext) -> Bool)`
- `commitEdit: ((_ ctx: EventContext, _ commit: UITableViewCellEditingStyle) -> Void)`
- `canMoveRow: ((EventContext) -> Bool)`
- `moveRow: ((_ ctx: EventContext, _ dest: IndexPath) -> Void)`
- `prefetch: ((_ models: [M], _ paths: [IndexPath]) -> Void)`
- `cancelPrefetch: ((_ models: [M], _ paths: [IndexPath]) -> Void)`
- `rowHeight: ((EventContext) -> CGFloat)`
- `rowHeightEstimated: ((EventContext) -> CGFloat)`
- `indentLevel: ((EventContext) -> Int)`
- `willDisplay: ((EventContext) -> Void)`
- `shouldSpringLoad: ((EventContext) -> Bool)`
- `editActions: ((EventContext) -> [UITableViewRowAction]?)`
- `tapOnAccessory: ((EventContext) -> Void)`
- `willSelect: ((EventContext) -> IndexPath?)`
- `tap: ((EventContext) -> TableSelectionState)`
- `willDeselect: ((EventContext) -> IndexPath?)`
- `didDeselect: ((EventContext) -> IndexPath?)`
- `willBeginEdit: ((EventContext) -> Void)`
- `didEndEdit: ((EventContext) -> Void)`
- `editStyle: ((EventContext) -> UITableViewCellEditingStyle)`
- `deleteConfirmTitle: ((EventContext) -> String?)`
- `editShouldIndent: ((EventContext) -> Bool)`
- `moveAdjustDestination: ((_ ctx: EventContext, _ proposed: IndexPath) -> IndexPath?)`
- `endDisplay: ((_ cell: C, _ path: IndexPath) -> Void)`
- `shouldShowMenu: ((EventContext) -> Bool)`
- `canPerformMenuAction: ((_ ctx: EventContext, _ sel: Selector, _ sender: Any?) -> Bool)`
- `performMenuAction: ((_ ctx: EventContext, _ sel: Selector, _ sender: Any?) -> Void)`
- `shouldHighlight: ((EventContext) -> Bool)`
- `didHighlight: ((EventContext) -> Void)`
- `didUnhighlight: ((EventContext) -> Void)`
- `canFocus: ((EventContext) -> Bool)`

### Received Context

`EventContext` is a typealias for Adapter's `Context<M,C>` with `M` is the `ModelProtocol` instance managed by the table and `C` is `CellProtocol` instance used to represent data.

The following properties are available:

- `table: UITableView`: target table instance
- `indexPath: IndexPath`: target model index path
- `model: M`: target model instance (type-safe)
- `cell: C?`: target cell instance (type-safe) / if available

### Example

```swift
let contactAdapter = TableAdapter<Contact,CellContact>()

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

## `TableSectionView` events

The following events are received from single instances of `headerView`/`footerView` of a `TableSection` instance and are related to header/footer events.

### Events

The following events are available from `TableSectionView `'s `.on` property.

**`height` event is required.**

- `dequeue: ((Context<T>) -> Void)`
- `height: ((Context<T>) -> CGFloat)`
- `estimatedHeight: ((Context<T>) -> CGFloat)`
- `willDisplay: ((Context<T>) -> Void)`
- `endDisplay: ((Context<T>) -> Void)`
- `didDisplay: ((Context<T>) -> Void)`

### Example

```swift
let header = TableSectionView<TableExampleHeaderView>()
header.on.height = { _ in
	return 150
}
header.on.dequeue = { ctx in
	ctx.view?.titleLabel?.text = "\(articles.count) Articles"
}

let section = TableSection(headerView: header, models: articles)
```

### Received Context

Where `Context<T>` is a structure which contains the following properties of the section view instance:

- `type: SectionType`: `header` if target view is header, `footer` for footer view
- `table: UITableView`: target table instance
- `view: T`: type-safe target instance of the header/footer view set
- `section: Int`: target section
- `tableSize: CGSize`: size of the target table
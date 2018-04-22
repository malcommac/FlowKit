# FlowKit

## What's FlowKit
FlowKit is a new approach to create, populate and manage `UITableView` and `UICollectionView`.

With a declarative and type-safe approach you **don't need to implement datasource/delegate** anymore: your code is easy to read, maintain and SOLID.

## Features Highlights

- **No more datasource/delegate**: you don't need to implements tons of methods just to render your data. Just plain understandable methods to manage what kind of data you want to display, remove or move.
- **Type-safe**: register pair of model/cell types you want to render, then access to instances of them in pure Swift type-safe style.
-  **Auto-Layout**: self-sized cells are easy to be configured, both for tables and collection views.
-  **Built-In Auto Animations**: changes & sync between your datasource and table/collection is evaluated automatically and you can get animations for free.
-  **Compact Code**: your code for table and collection is easy to read & maintain; changes in datasource are done declaratively via `add`/`move` and `remove` functions (both for sections, header/footers and single rows). 


## What you will get
The following code is just a small example which shows how to make a simple Contacts list UITableView using FlowKit (it works similar with collection too):

```swift
// Create a director which manage the table/collection
let director = TableDirector(self.tableView)

// Declare an adapter which renders Contact Model using ContactCell
let cAdapter = TableAdapter<Contact,ContactCell>()

// Hook events you need
// ...dequeue
cAdapter.on.dequeue = { ctx in
	self.fullNameLabel.text = "\(ctx.model.firstName) \(ctx.model.lastName)"
	self.imageView.image = loadFromURL(ctx.model.avatarURL)
}
// ...tap (or all the other events you typically have for tables/collections)
cAdapter.on.tap = { ctx in
	openDetail(forContact: ctx.model)
}

// Register adapter; now the director know how to render your data
director.register(adapter: cAdapter)

// Manage your source by adding/removing/moving sections & rows
director.add(models: arrayOfContacts)
// Finally reload your table
director.reloadData()
```

Pretty simple uh?

No datasource, no delegate, just a declarative syntax to create & manage your data easily and in type-safe manner (both for models and cells).
Learn more about sections, header/footer & events by reading the rest of guide.

## Documentation

**How to use FlowKit**

- Create the Director
- Register Adapters
- Create Data Models
- Create Cells
- Add Sections
- Setup Headers & Footers
- Reload Data with/out Animations

**Events**

**Table Events**

- `TableDirector` (general table events)
- `TableSection` (events specific for sections)
- `TableSectionView` (events specific for header/footer)

**Collection Events**

- `CollectionDirector` (general collection events)
- `CollectionSection` (events specific for sections)
- `CollectionSectionView` (events specific for header/footer)

- `UIScrollViewDelegate` events (generic `UIScrollView` events)

-- 

### How to use FlowKit

**Note**: *The following concepts are valid even if work with tables or collections using FlowKit (each class used starts with `Table[...]` or `Collection[...]` prefixes and where there are similaties between functions the name of functions/properties are consistence).*

In FlowKit there are two important entities you will encounter: the Director and the Adapter.

#### Create the Director (`TableDirector`/`CollectionDirector`)

You can think about the Director has the owner/manager of the table/collection: using it you can declare what kind of data your scroller is able to show (both models and views/cells), add/remove/move both sections and items in sections.
Since you will start using FlowKit you will use the director instance to manage the content of the UI.

*Keep in mind: a single director instance is able to manage only a single instance of a scroller.*

You have two ways to set a director; explicitly:

```swift
public class ViewController: UIViewController {
	@IBOutlet public var tableView: UITableView?
	private var director: TableDirector?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.director = TableDirector(self.tableView!)	
	}
}
```

or using implicitly, by accessing to the `director` property: the first time you call it a new director instance is created and assigned with strong reference to the table/collection instance.

```swift
let director = self.tableView.director // create a director automatically
// do something with it...
```

#### Register Adapters (`TableAdapter`/`CollectionAdapter`)

Once you have a director you need to tell to it what kind of data you are about to render: you can have an etherogeneus collection of Models and View (cells) in your scroller but a single Model can be rendered to a single type of View.

Suppose you want to render two types of models:

- `Contact` instances using `ContactCell` view
- `ContactGroup` instances using `ContactGroupCell` view

You will need two adapters:

```swift
let contactAdpt = TableAdapter<Contact,ContactGroup>()
let groupAdpt = TableAdapter<ContactGroup,ContactGroupCell>()
tableView.director.register(adapters: [contactAdpt, groupAdpt])
```

Now you are ready to present your data.

#### Create Data Models (`ModelProtocol`)

In order to render your data each object of the scroller must be conform to `ModelProtocol` which includes:

- Must be conform to `Hashable` protocol (this is used to perform built-in automatic animations we'll see later)
- Must implement a simple `identifier` property (used above)

This is an example implementation of `Contact` model:

```swift
public class Contact: ModelProtocol, Hashable {
	public var name: String
	public var GUID: String = NSUUID().uuidString

	public var identifier: Int {
		return GUID.hashValue
	}
	
	public static func == (lhs: Contact, rhs: Contact) -> Bool {
		return lhs.GUID == rhs.GUID
	}
		
	public init(_ name: String) {
		self.name = name
	}
}
```

#### Create Cells (`UITableViewCell`/`UICollectionViewCell`)

Both `UITableViewCell` and `UICollectionViewCell` and its subclasses are automatically conforms to `CellProtocol`.

The only constraint is about `reuseIdentifier`: **cells must have`reuseIdentifier` (`Identifier` in Interface Builder) the name of the class itself.**.

If you need you can override this behaviour by overrinding the  `reuseIdentifier: String` property of your cell and returing your own identifier.

Cell can be loaded in three ways:

- **Cells from Storyboard**: This is the default behaviour; you don't need to do anything, cells are registered automatically.
- **Cells from XIB files**: Be sure your xib files have the same name of the class (ie. `ContactCell.xib`) and the cell as root item.
- **Cells from `initWithFrame`**: Override `CellProtocol`'s `registerAsClass` to return `true`.

This is a small example of the `ContactCell`:

```swift
public class ContactCell: UITableViewCell {
	@IBOutlet public var labelName: UILabel?
	@IBOutlet public var labelSurname: UILabel?
	@IBOutlet public var icon: UIImageView?
}
```

#### Add Sections (`TableSection`/`CollectionSection`)

Each Table/Collection must have at least one section to show something.
`TableSection`/`CollectionSection` instances hold the items to show (into `.models` property) and optionally any header/Footer you can apply.

In order to manage sections of your table you need to use the following methods of the parent Director:

- `set(models:)` change the section of the table/collection.
- `section(at:)` return section at index.
- `firstSection()` return first section, if any.
- `lastSection()` return last section, if any.
- `add(section:at:)` add or insert a new section.
- `add(sections:at:)` add an array of sections.
- `add(models:)` create a new section with given models inside and add it.
- `removeAll(keepingCapacity:)` remove all sections.
- `remove(section:)` remove section at given index.
- `remove(sectionsAt:)` remove sections at given indexes set.
- `move(swappingAt:with:)` swap section at given index with destination index.
- `move(from:to)` combo remove/insert of section at given index to destination index.

The following example create a new `TableSection` with some items inside, a `String` based header, then append it a the end of the table.

```swift
let section = TableSection(headerTitle: "The Strangers", items: [mrBrown,mrGreen,mrWhite])
table.director.add(section: section)
```

#### Manage Models in Section

As for section the same `add`/`remove`/`move` function are also available for `models` array which describe the content (rows/items) inside each section (`TableSection`/`CollectionSection` instances).

This is the complete list:

- `set(models:)` change models array.
- `add(model:at:)` add model at given index, if nil is append at the bottom.
- `add(models:at:)` add models starting at given index; if nil models are append at the bottom.
- `remove(at:)` remove model at given index.
- `remove(atIndexes:)` remove models at given index set.
- `removeAll(keepingCapacity:)` remove all models of the section.
- `move(swappingAt:with:)` Swap model at given index to another destination index.
- `move(from:to:)` Remove model at given index and insert at destination index.

After any change you must call the `director.reloadData()` function from main thread to update the UI.

This is an example of items management:

```swift
let section = self.tableView.director.firstSection()

let newItems = [Contact("Daniele","Margutti"),Contact("Fabio","Rossi")]
section.add(models: newItems) // add two new contacts
section.remove(at: 0) // remove first item

// ...
self.tableView.director.reloadData() // reload data
```


#### Setup Headers & Footers (`TableSectionView`/`CollectionSectionView`)

**Simple Header/Footer**

Section may have or not headers/footers; these can be simple `String` (as you seen above) or custom views.

Setting simple headers is pretty straightforward, just set the `headerTitle`/`footerTitle`:

```swift
section.headerTitle = "New Strangers"
section.footerTitle = "\(contacts.count) contacts")
```
**Custom View Header/Footer**

To use custom view as header/footer you need to create a custom `xib` file with a `UITableViewHeaderFooterView` (for table) or `UICollectionReusableView` (for collection) view subclass as root item.

The following example shows a custom header and how to set it:

```swift
// we also need of TableExampleHeaderView.xib file
// with TableExampleHeaderView view as root item
public class TableExampleHeaderView: UITableViewHeaderFooterView {
	@IBOutlet public var titleLabel: UILabel?
}

// create the header container (will receive events)
let header = TableSectionView<TableExampleHeaderView>()
// hooks any event. You need at least the `height` as below
header.on.height = { _ in
	return 150
}

// Use it
let section = TableSection(headerView: header, items: [mrBrown,mrGreen,mrWhite])
table.director.add(section: section)
```

#### Reload Data with/out Animations

Each change to the data model must be done by calling the `add`/`remove`/`move` function available both at sections and items levels.
After changes you need to call the director's `reloadData()` function to update the UI.

The following example update a table after some changes:

```swift
// do some changes
tableView.director.remove(section: 0)
tableView.director.add(section: newSection, at: 2)
...
tableView.director.firstSection().remove(at: 0)

// then reload
tableView.director.reloadData()
```

If you need to perform an animated reload just make your changes to the model inside the callback available into the method.
Animations are evaluated and applied for you!

```swift
tableView.director.reloadData(after: { _ in
	tableView.director.remove(section: 0)
	tableView.director.add(section: newSection, at: 2)
	
	return TableReloadAnimations.default()
})
```

For `TableDirector` you must provide a `TableReloadAnimations` configuration which defines what kind of `UITableViewRowAnimation` must be applied for each type of change (insert/delete/reload/move). `TableReloadAnimations.default()` just uses `.automatic` for each type.

For `CollectionDirector` you don't need to return anything; evaluation is made for you based upon the layout used.

--
### Events

All events are hookable from their respective objects starting from `.on` property. All standard table & collections events are available from FlowKit; name of the events is similar to the their standard corrispettive in UIKit (see the official documentation for more info abou any specific event).


#### Table Events

**`TableDirector` (general table events)**

The following events are available from `TableDirector `'s `.on` property.

- `sectionForSectionIndex: ((_ title: String, _ index: Int) -> Int)` (name of the section is read automatically from `indexTitle` property of the section)
- `willDisplayHeader: ((HeaderFooterEvent) -> Void)`
- `willDisplayFooter: ((HeaderFooterEvent) -> Void)`
- `endDisplayHeader: ((HeaderFooterEvent) -> Void)`
- `endDisplayFooter: ((HeaderFooterEvent) -> Void)`

where `HeaderFooterEvent` is just a typealias:

- `HeaderFooterEvent = (view: UIView, section: Int, table: UITableView)`

--

**`TableAdapter` (items/models related events)**

The following events are available from `TableAdapter `'s `.on` property.

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

Where `EventContext` is a typealias for Adapter's `Context<M,C>` with `M` is the `ModelProtocol` instance managed by the table and `C` is `CellProtocol` instance used to represent data.

The following properties are available:

- `table: UITableView`: target table instance
- `indexPath: IndexPath`: target model index path
- `model: M`: target model instance (type-safe)
- `cell: C?`: target cell instance (type-safe) / if available

-- 

**`TableSectionView` (events specific for header/footer)**

The following events are available from `TableSectionView `'s `.on` property.

- `dequeue: ((Context<T>) -> Void)`
- `height: ((Context<T>) -> CGFloat)`
- `estimatedHeight: ((Context<T>) -> CGFloat)`
- `willDisplay: ((Context<T>) -> Void)`
- `endDisplay: ((Context<T>) -> Void)`
- `didDisplay: ((Context<T>) -> Void)`

Where `Context<T>` is a structure which contains the following properties of the section view instance:

- `type: SectionType`: `header` if target view is header, `footer` for footer view
- `table: UITableView`: target table instance
- `view: T`: type-safe target instance of the header/footer view set
- `section: Int`: target section
- `tableSize: CGSize`: size of the target table

**Collection Events**

**`CollectionDirector` (general collection events)**

The following events are available from `CollectionDirector `'s `.on` property.

- `layoutDidChange: ((_ old: UICollectionViewLayout, _ new: UICollectionViewLayout) -> UICollectionViewTransitionLayout?)`
- `targetOffset: ((_ proposedContentOffset: CGPoint) -> CGPoint)`
- `moveItemPath: ((_ originalIndexPath: IndexPath, _ proposedIndexPath: IndexPath) -> IndexPath)`
- `shouldUpdateFocus: ((_ context: UICollectionViewFocusUpdateContext) -> Bool)`
- `didUpdateFocus: ((_ context: UICollectionViewFocusUpdateContext, _ coordinator: UIFocusAnimationCoordinator) -> Void)`
- `willDisplayHeader : ((HeaderFooterEvent) -> Void)`
- `willDisplayFooter : ((HeaderFooterEvent) -> Void)`
- `endDisplayHeader : ((HeaderFooterEvent) -> Void)`
- `endDisplayFooter : ((HeaderFooterEvent) -> Void)`

Where `HeaderFooterEvent` is a typealias for:

- `HeaderFooterEvent = (view: UICollectionReusableView, path: IndexPath, table: UICollectionView)`

-- 

**`CollectionAdapter` (items/models related events)**

The following events are available from `CollectionAdapter `'s `.on` property.

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

Where `EventContext` is a typealias for Adapter's `Context<M,C>` with `M` is the `ModelProtocol` instance managed by the collection and `C` is `CellProtocol` instance used to represent data.

The following properties are available:

- `indexPath: IndexPath`: target model's index path
- `model: M`: type-safe instance of the model
- `cell: C`: type-safe instance of the cell
- `collection: UICollectionView`: parent collection view
- `collectionSize: CGSize`: parent collection view's size

--

**CollectionSectionView` (events specific for header/footer)**

The following events are available from `CollectionSectionView`'s `.on` property.

- `dequeue: ((EventContext) -> Void)`
- `referenceSize: ((EventContext) -> CGSize)`
- `didDisplay: ((EventContext) -> Void)`
- `endDisplay: ((EventContext) -> Void)`
- `willDisplay: ((EventContext) -> Void)`

where `EventContext` is a typealias for `Context<T>` where `T` is the instance of `UICollectionReusableView` header/footer set.

The following properties are available:

- `section: Int`: section of the item
- `type: SectionType`: type of view (`footer` or `header`)
- `view: T`: type safe instance of th header/footer
- `collection: UICollectionView`: parent collection view
- `collectionSize: CGSize`: parent collection view's size

-- 

**`UIScrollViewDelegate` events (generic `UIScrollView` events)**

The following events are available from director's `.onScroll` property both for `TableDirector` and `CollectionDirector`.

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
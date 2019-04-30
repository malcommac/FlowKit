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

- Main Concepts: Director & Adapters
	- Director
	- Adapters
- Getting Started
- How-To
	- Create Model
	- Create UI (cells)
	- Manage Self-Sized Cells
	- Loading Cells from Storyboard, Xib or class
- APIs Documentation: Table
	- `TableDirector`
	- `TableSection`
	- `TableAdapter`
- APIs Documentation: Collection
	- `CollectionDirector`
	- `FlowCollectionDirector`
	- `CollectionSection`
	- `CollectionAdapter`

### Main Concepts: Director & Adapters

All the FlowKit's SDK is based upon two concepts: the **director** and the **adapter**.

#### Director

The **director** is the class which manage the content of a list, keep in sync data with UI and offers all the methods and properties to manage it. When you need to add, move or remove a section or a cell, change the header or a footer you find all the methods and properties in this class.
A director instance can be associated with only one list (table or collection); once a director is assigned to a list it become the datasource and delegate of the object.

The following directors are available:

- `TableDirector` used to manage `UITableView` instances
- `CollectionDirector` and `FlowCollectionDirector` used to manage `UICollectionView` with custom or `UICollectionViewFlowLayout` layout.

#### Adapters

Once you have created a new director for a list it's time to declare what kind of models your list can accept. Each model is assigned to one UI element (`UITableViewCell` subclass for tables, `UICollectionViewCell` subclass for collections).

The scope of the adapter is to declare a pair of Model & UI a director can manage. 

The entire framework is based to this concept: a model can be rendered by a single UI elements and its up to FlowKit to pick the right UI for a particular model instance.

An adapter is also the centrail point to receive events where a particular instance of a model is involved in. For example: when an user tap on a row for a model instance of type A, you will receive the event (along with the relevant info: index path, involved model instance etc.) inside the adapter which manage that model.

You will register as much adapters as models you have.

### Getting Started

The following code shows how to create a director to manage an `UITableView` (a much similar approach is used for `UICollectionView`).

```swift
public class MyController: UIViewController {
	@IBOutlet public var table: UITableView!
	
	private var director: TableDirector?
	
	func viewDidLoad() {
		super.viewDidLoad()
		director = TableDirector(table: table)
// ...
```

It's now time to declare what kind of content should manage our director. For shake of simplicity we'll declare just an adapter but you can declare how much adapters you need (you can also create your own director with adapters inside and reuse them as you need. This is a neat approach to reuse and decupling data).

```swift
	func viewDidLoad() {
		// ...
		let contactAdpt = TableCellAdapter<Contact, ContactCell>()
		contactAdpt.events.rowHeight = { ctx in
       		return 60.0 // explicit row height
        }
        contactAdpt.events.dequeue = { ctx in
           // this is the suggested behaviour; your cell should expose a
           // property of the type of the model it can be render and you will
           // assign it on dequeue. It's type safe too!!
			ctx.cell?.contact = ctx.element
		}
		director?.registerCellAdapter(contactAdpt)
```

This is minimum setup to render objects of type `Contact` using cell of type `ContactCell` using our director.
You can configure and attach tons of other properties and events (using the adapter's `.events` property); you will found a more detailed description of each property below but all `UITableView`/`UICollectionView`'s events and properties are supported.

Now it's time to add some content to our table.
As we said FlowKit uses a declarative approach to content: this mean you set the content of a list by using imperative functions like `add`,`remove`,`move` both for sections and elements.

```swift
	let contacts = [
		Contact(first: "John", last: "Doe"),
		Contact(first: "Adam", last: "Best"),
		...
	]
	// ...
    director?.add(elements: contacts)
```

The following code create (automatically) a new `TableSection` with the `contacts` elements inside. If you need you can create a new section manually:

```swift
	// Create a new section explicitly. Each section has an unique id you can assign
	// explicitly or leave FlowKit create an UUID for you. It's used for diff features.
	let newSection = TableSection(id: "mySectionId", elements: contacts, header: "\(contacts) Contacts", footer: nil)
    director?.add(section: newSection)
```

In order to sync the UI just call the `director?.reload()`, et voilà!
Just few lines of code to create a fully functional list!

At anytime you are able to add new sections, move or replace items just by using the methods inside the `TableSection`/`CollectionSection` or `TableDirector`/`CollectionDirector` instances then calling `reload()` to refresh the content.

Refresh is made without animation, but FlowKit is also able to refresh the content of your data by picking the best animation based on a blazing fast diff algorithm which compare the data before/after your changes. More details in the next chapter. 

### How-To

#### Create Model

Models can be struct or classes; the only requirement is the conformance to `ElementRepresentable` protocol.
This protocol is used by the diff algorithm in order to evaluate the difference between changes applied to models and pick the best animation to show it.

This means you don't need to make any `performBatches` update neither to call `reloadRows/removeRows/addRows` methods manually... all these boring and crash-proned stuff are made automatically by FlowKit.

The following example show our `Contact` model declaration:

```swift
public class Contact: ElementRepresentable {
    let firstName: String
    let lastName: String

	public var differenceIdentifier: String {
		return "\(self.firstName)_\(self.lastName)"
	}

	public func isContentEqual(to other: Differentiable) -> Bool {
		guard let other = other as? Contact else { return false }
		return other == self
	}

	init(first: String, last: String) {
		self.firstName = first
		self.lastName = last
	}
}
```
##### Protocol Conformance

Protocol conformance is made by adding:

- `differenceIdentifier` property: An model needs to be uniquely identified to tell if there have been any insertions or deletions (it's the perfect place for a `uuid` property)
- `isContentEqual(to:)` function: is used to check if any properties have changed, this is for replacement changes. If your model data change between reloads FlowKit updates the cell's UI accordingly.

#### Create UI (Cells)

The second step is to create an UI representation of your model. Typically is a subclass of `UITableViewCell` or `UICollectionViewCell`.

##### Reuse Identifier

Cells must have as `reuseIdentifier` value the same name of the class itself (so `ContactCell` has also `ContactCell` as identifier; you can also configure it if you need but it's a good practice).

##### Loading Cells from Storyboard, Xib or class

By default cells are loaded from managed table/collection instance storyboard but sometimes you may also need to load them from external files like xib.
In this case you must override the static `reusableViewSource` property of your cell subclass and provide the best loading source between values of `ReusableViewSource`:

- `fromStoryboard`: load from storyboard (the default value, use it when your cell is defined as prototype inside table's instance).
- `fromXib(name: String?, bundle: Bundle?)`: load from a specific xib file in a bundle (if `name` is nil it uses the same filename of the cell class, ie `ContactCell.xib`; if `bundle` is `nil` it uses the same bundle of your cell class.
- `fromClass`: loading from class.

The following example load a cell from an external xib file named `MyContactCell.xib`:

```swift
public class ContactCell: UITableViewCell {
    // ...
    
    public static var reusableViewSource: ReusableViewSource {
        return .fromXib(name: "MyContactCell", bundle: nil)
    }
}
```

##### Best Practices

You don't need to conform any special protocol but, in order to keep your code clean, our suggestion is to create a public property which accepts the model instance and set it on adapter's `dequeue` event.

```swift
public class ContactCell: UITableViewCell {

	// Your outlets
    @IBOutlet public var ...

	// Define a property you set on adapter's dequeue event
	public var contact: Contact? {
		didSet {
           // setup your UI according with instance data
		}
	}
}
```

In your adapter:

```swift
contactAdpt.events.dequeue = { ctx in
	ctx.cell?.contact = ctx.element
}
```

`ctx` is an object which includes all the necessary informations of an event, including type-safe instance of the model.

#### Manage Self-Sized Cells

Self-sized cells are easy to be configured, both for tables and collection views.

FlowKit support easy cell sizing using autolayout. You can set the size of the cell by adapter or collection/table based. For autolayout driven cell sizing set the `rowHeight` (for `TableDirector`) or `itemSize` (for `CollectionDirector`/`FlowCollectionDirector`) to the autoLayout value, then provide an estimated value.

Accepted values are:

- `default`: you must provide the height (table) or size (collection) of the cell
- `auto(estimated: CGFloat)`: uses autolayout to evaluate the height of the cell; for Collection Views you can also provide your own calculation by overriding `preferredLayoutAttributesFitting()` function in cell instance.
- `explicit(CGFloat)`: provide a fixed height for all cell types (faster if you plan to have all cell sized same)

### APIs Documentation

#### `TableDirector`


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
			ctx.cell?.contactItem = ctx.element
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
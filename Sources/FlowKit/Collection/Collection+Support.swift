//
//	Flow
//	A declarative approach to UICollectionView & UITableView management
//	--------------------------------------------------------------------
//	Created by:	Daniele Margutti
//				hello@danielemargutti.com
//				http://www.danielemargutti.com
//
//	Twitter:	@danielemargutti
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Foundation
import UIKit

//MARK: - ModelProtocol

public protocol ModelProtocol {
	
	/// Implementation of the protocol require the presence of id property which is used
	/// to uniquely identify an model. This is used by the DeepDiff library to evaluate
	/// what cells are removed/moved or deleted from table/collection and provide the right
	/// animation without an explicitly animation set.
	///
	/// NOTE:
	/// Default implementation of this property is provided by any class via the extension
	/// for `AnyObject` using the `ObjectIdentifier`.
	/// An explicit implementation must be done by the developer for struct.
	var modelID: Int { get }
	
}

extension ModelProtocol where Self : AnyObject {
	
	/// Default implementation of the ModelProtocol protocol is provided for any class using
	/// the `ObjectIdentifier`. You can still implement your own item.
	public var modelID: Int {
		return ObjectIdentifier(self).hashValue
	}
	
}

//MARK: - CellProtocol Implementation

extension UICollectionViewCell: CellProtocol { }

public protocol CellProtocol: class {
	static var reuseIdentifier: String { get }
	static var registerAsClass: Bool { get }
}

public extension CellProtocol {
	
	/// By default the identifier of the cell is the same name of the cell.
	static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	/// Return true if you want to allocate the cell via class name using classic
	/// `initWithFrame`/`initWithCoder`. If your cell UI is defined inside a nib file
	/// or inside a storyboard you must return `false`.
	static var registerAsClass : Bool {
		return false
	}
	
}

//MARK: - HeaderFooterProtocol

public protocol HeaderFooterProtocol: class {
	static var reuseIdentifier: String { get }
	static var registerAsClass: Bool { get }
}

public extension HeaderFooterProtocol {
	
	/// By default the identifier of the cell is the same name of the cell.
	static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	/// Return true if you want to allocate the cell via class name using classic
	/// `initWithFrame`/`initWithCoder`. If your cell UI is defined inside a nib file
	/// or inside a storyboard you must return `false`.
	static var registerAsClass : Bool {
		return false
	}
}

extension UITableViewHeaderFooterView: HeaderFooterProtocol {
	
	/// By default it uses the same name of the class.
	public static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	/// Return true if you want to allocate the cell via class name using classic
	/// `initWithFrame`/`initWithCoder`. If your header/footer UI is defined inside a nib file
	/// or inside a storyboard you must return `false`.
	public static var registerAsClass: Bool {
		return false
	}

}

extension UICollectionReusableView : HeaderFooterProtocol {
	
	/// By default it uses the same name of the class.
	public static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	/// Return true if you want to allocate the cell via class name using classic
	/// `initWithFrame`/`initWithCoder`. If your header/footer UI is defined inside a nib file
	/// or inside a storyboard you must return `false`.
	public static var registerAsClass: Bool {
		return false
	}

}

//MARK: - Abstract Protocols

public protocol AbstractAdapterProtocol {
	var modelType: Any.Type { get }
	var cellType: Any.Type { get }
	var cellReuseIdentifier: String { get }
	var cellClass: AnyClass { get }
	var registerAsClass: Bool { get }
	
}

public protocol AbstractCollectionReusableView {
	var viewClass: AnyClass { get }
	var reuseIdentifier: String { get }
	var registerAsClass: Bool { get }
}

//MARK: - Internal Protocols

internal protocol AbstractCollectionHeaderFooterItem {
	
	@discardableResult
	func dispatch(_ event: CollectionSectionViewEventsKey, type: SectionType,  view: UICollectionReusableView?, section: Int, collection: UICollectionView) -> Any?
	
}

public protocol CollectionSectionProtocol : AbstractCollectionReusableView {
	var section: CollectionSection? { get set }
}


internal protocol AbstractAdapterProtocolFunctions {

	@discardableResult
	func dispatch(_ event: CollectionAdapterEventKey, context: InternalContext) -> Any?
	
	func _instanceCell(in collection: UICollectionView, at indexPath: IndexPath?) -> UICollectionViewCell
}

public protocol CollectionAdapterProtocol : AbstractAdapterProtocol, Equatable {
	
}

internal enum CollectionAdapterEventKey: Int {
	case dequeue
	case shouldSelect
	case shouldDeselect
	case didSelect
	case didDeselect
	case didHighlight
	case didUnhighlight
	case shouldHighlight
	case willDisplay
	case endDisplay
	case shouldShowEditMenu
	case canPerformEditAction
	case performEditAction
	case canFocus
	case itemSize
	//case generateDragPreview
	//case generateDropPreview
	case prefetch
	case cancelPrefetch
	case shouldSpringLoad
}

internal enum CollectionSectionViewEventsKey: Int {
	case dequeue
	case referenceSize
	case didDisplay
	case endDisplay
	case willDisplay
}

public extension UICollectionView {
	
	private static let DIRECTOR_KEY = "flowkit.director"
	
	/// Return director associated with collection.
	/// If not exist it will be created and assigned automatically.
	public var director: FlowCollectionDirector {
		get {
			return getAssociatedValue(key: UICollectionView.DIRECTOR_KEY,
									  object: self,
									  initialValue: FlowCollectionDirector(self))
		}
		set {
			set(associatedValue: newValue, key: UICollectionView.DIRECTOR_KEY, object: self)
		}
	}
	
}

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

public extension UITableView {
	
	private static let DIRECTOR_KEY = "flowkit.director"
	
	/// Return director associated with collection.
	/// If not exist it will be created and assigned automatically.
	public var director: TableDirector {
		get {
			return getAssociatedValue(key: UITableView.DIRECTOR_KEY,
									  object: self,
									  initialValue: TableDirector(self))
		}
		set {
			set(associatedValue: newValue, key: UITableView.DIRECTOR_KEY, object: self)
		}
	}
	
}

/// State of the section
///
/// - none: don't change the state
/// - deselect: deselect without animation
/// - deselectAnimated: deselect with animation
public enum TableSelectionState {
	case none
	case deselect
	case deselectAnimated
}

public enum TableAnimationAction {
	case delete
	case insert
	case reload
}

public protocol TableReloadAnimationProtocol {
	
	func animationForRow(action: TableAnimationAction) -> UITableView.RowAnimation
	func animationForSection(action: TableAnimationAction) -> UITableView.RowAnimation
	
}

public extension TableReloadAnimationProtocol {
	
	func animationForRow(action: TableAnimationAction) -> UITableView.RowAnimation {
		return .automatic
	}
	
	func animationForSection(action: TableAnimationAction) -> UITableView.RowAnimation {
		return .automatic
	}
	
}

/// Animations used with reload
public struct TableReloadAnimations: TableReloadAnimationProtocol {
	public static func `default`() -> TableReloadAnimations {
		return TableReloadAnimations()
	}
}

// Protocols

extension UITableViewCell: CellProtocol { }

public protocol TableAdapterProtocol : AbstractAdapterProtocol, Equatable { }

internal protocol AbstractTableHeaderFooterItem  {
	@discardableResult
	func dispatch(_ event: TableSectionViewEventsKey, type: SectionType, view: UIView?, section: Int, table: UITableView) -> Any?
}

public protocol TableHeaderFooterProtocol : AbstractCollectionReusableView {
	var section: TableSection? { get set }
}

internal protocol TableAdaterProtocolFunctions {
	
	@discardableResult
	func dispatch(_ event: TableAdapterEventsKey,  context: InternalContext) -> Any?
	
	// Dequeue (UITableViewDatasource)
	func _instanceCell(in table: UITableView, at indexPath: IndexPath?) -> UITableViewCell
}

internal protocol TableDirectorEventable {
	var name: TableDirectorEventKey { get }
}

internal enum TableDirectorEventKey: String {
	case sectionForSectionIndex
}

internal enum TableSectionViewEventsKey: Int {
	case dequeue
	case height
	case estimatedHeight
	case didDisplay
	case endDisplay
	case willDisplay
}

internal enum TableAdapterEventsKey: Int {
	case dequeue = 0
	case canEdit
	case commitEdit
	case canMoveRow
	case moveRow
	case prefetch
	case cancelPrefetch
	case rowHeight
	case rowHeightEstimated
	case indentLevel
	case willDisplay
	case shouldSpringLoad
	case editActions
	case tapOnAccessory
	case willSelect
	case tap
	case willDeselect
	case didDeselect
	case willBeginEdit
	case didEndEdit
	case editStyle
	case deleteConfirmTitle
	case editShouldIndent
	case moveAdjustDestination
	case endDisplay
	case shouldShowMenu
	case canPerformMenuAction
	case performMenuAction
	case shouldHighlight
	case didHighlight
	case didUnhighlight
	case canFocus
	case leadingSwipeActions
	case trailingSwipeActions
}

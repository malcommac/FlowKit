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

/// Adapter manages a model type with its associated view representation (a particular cell type).
open class TableAdapter<M: ModelProtocol, C: CellProtocol>: TableAdapterProtocol,TableAdaterProtocolFunctions {

	/// TableAdapterProtocol conformances
	public var modelType: Any.Type = M.self
	public var cellType: Any.Type = C.self
	public var cellReuseIdentifier: String { return C.reuseIdentifier }
	public var cellClass: AnyClass { return C.self }
	public var registerAsClass: Bool { return C.registerAsClass }
	
	public static func == (lhs: TableAdapter<M, C>, rhs: TableAdapter<M, C>) -> Bool {
		return 	(String(describing: lhs.modelType) == String(describing: rhs.modelType)) &&
				(String(describing: lhs.cellType) == String(describing: rhs.cellType))
	}
	
	
	/// Events of the adapter
	public var on: Events<M,C> = Events()

	/// Initialize a new adapter with optional configuration callback.
	///
	/// - Parameter configuration: configuration callback
	public init(_ configuration: ((TableAdapter) -> (Void))? = nil) {
		configuration?(self)
	}
	
	//MARK: TableAdaterProtocolFunctions Protocol
	
	func _instanceCell(in table: UITableView, at indexPath: IndexPath?) -> UITableViewCell {
		guard let indexPath = indexPath else {
			let castedCell = self.cellClass as! UITableViewCell.Type
			let cellInstance = castedCell.init()
			return cellInstance
		}
		return table.dequeueReusableCell(withIdentifier: C.reuseIdentifier, for: indexPath)
	}

	func dispatch(_ event: TableAdapterEventsKey, context: InternalContext) -> Any? {
		switch event {
			
		case .dequeue:
			guard let callback = self.on.dequeue else { return nil }
			callback(Context<M,C>(generic: context))
		
		case .canEdit:
			guard let callback = self.on.canEdit else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .commitEdit:
			guard let callback = self.on.commitEdit else { return nil }
            return callback(Context<M,C>(generic: context), (context.param1 as! UITableViewCell.EditingStyle))
			
		case .canMoveRow:
			guard let callback = self.on.canMoveRow else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .moveRow:
			guard let callback = self.on.moveRow else { return nil }
			callback(Context<M,C>(generic: context), (context.param1 as! IndexPath))
			
		case .prefetch:
			guard let callback = self.on.prefetch else { return nil }
			callback( (context.models as! [M]), context.paths!)
			
		case .cancelPrefetch:
			guard let callback = self.on.cancelPrefetch else { return nil }
			callback( (context.models as! [M]), context.paths!)
			
		case .rowHeight:
			guard let callback = self.on.rowHeight else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .rowHeightEstimated:
			guard let callback = self.on.rowHeightEstimated else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .indentLevel:
			guard let callback = self.on.indentLevel else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .willDisplay:
			guard let callback = self.on.willDisplay else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .shouldSpringLoad:
			guard let callback = self.on.shouldSpringLoad else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .editActions:
			guard let callback = self.on.editActions else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .tapOnAccessory:
			guard let callback = self.on.tapOnAccessory else { return nil }
			callback(Context<M,C>(generic: context))
			
		case .willSelect:
			guard let callback = self.on.willSelect else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .tap:
			guard let callback = self.on.tap else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .willDeselect:
			guard let callback = self.on.willDeselect else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .didDeselect:
			guard let callback = self.on.didDeselect else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .willBeginEdit:
			guard let callback = self.on.willBeginEdit else { return nil }
			callback(Context<M,C>(generic: context))
			
		case .didEndEdit:
			guard let callback = self.on.didEndEdit else { return nil }
			callback(Context<M,C>(generic: context))
			
		case .editStyle:
			guard let callback = self.on.editStyle else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .deleteConfirmTitle:
			guard let callback = self.on.deleteConfirmTitle else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .editShouldIndent:
			guard let callback = self.on.editShouldIndent else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .moveAdjustDestination:
			guard let callback = self.on.moveAdjustDestination else { return nil }
			return callback(Context<M,C>(generic: context), (context.param1 as! IndexPath))
			
		case .endDisplay:
			guard let callback = self.on.endDisplay else { return nil }
			callback((context.cell as! C), context.path!)
			
		case .shouldShowMenu:
			guard let callback = self.on.shouldShowMenu else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .canPerformMenuAction:
			guard let callback = self.on.canPerformMenuAction else { return nil }
			return callback(Context<M,C>(generic: context), (context.param1 as! Selector), context.param2)
			
		case .performMenuAction:
			guard let callback = self.on.performMenuAction else { return nil }
			return callback(Context<M,C>(generic: context), (context.param1 as! Selector), context.param2)
			
		case .shouldHighlight:
			guard let callback = self.on.shouldHighlight else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .didHighlight:
			guard let callback = self.on.didHighlight else { return nil }
			callback(Context<M,C>(generic: context))
			
		case .didUnhighlight:
			guard let callback = self.on.didUnhighlight else { return nil }
			callback(Context<M,C>(generic: context))
			
		case .canFocus:
			guard let callback = self.on.canFocus else { return nil }
			return callback(Context<M,C>(generic: context))
			
		case .leadingSwipeActions:
			if #available(iOS 11, *) {
				guard let callback = self.on.leadingSwipeActions else { return nil }
				return callback(Context<M,C>(generic: context))
			} else {
				debugPrint("Supported only for iOS 11 or higher")
			}
			
		case .trailingSwipeActions:
			if #available(iOS 11, *) {
				guard let callback = self.on.trailingSwipeActions else { return nil }
				return callback(Context<M,C>(generic: context))
			} else {
				debugPrint("Supported only for iOS 11 or higher")
			}
		}
		return nil
	}

}

public extension TableAdapter {
	
	/// Context of the adapter.
	/// A context is sent when an event is fired and includes type-safe informations (context)
	/// related to triggered event.
	public struct Context<M,C> {

		/// Parent table
		public private(set) weak var table: UITableView?

		/// Index path
		public let indexPath: IndexPath
		
		/// Model instance
		public let model: M
		
		
		/// Cell instance
		/// NOTE: For some events cell instance is not reachable and may return `nil`.
		public var cell: C? {
			guard let callback = _cell else {
				return table?.cellForRow(at: self.indexPath) as? C
			}
			return callback
		}
		private let _cell: C?
		
		internal init(generic: InternalContext) {
			self.model = (generic.model as! M)
			self._cell = (generic.cell as? C)
			self.indexPath = generic.path!
			self.table = (generic.container as! UITableView)
		}

		/// Instance a new context with given data.
		/// Init of these objects are reserved.
		internal init(model: ModelProtocol, cell: CellProtocol?, path: IndexPath, table: UITableView) {
			self.model = model as! M
			self._cell = cell as? C
			self.indexPath = path
			self.table = table
		}
	}
	
}

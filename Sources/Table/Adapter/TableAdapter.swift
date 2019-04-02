//
//  TableAdapter.swift
//  FlowKit2
//
//  Created by dan on 04/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

open class TableAdapter<Model: ElementRepresentable, Cell: ReusableViewProtocol>: TableAdapterProtocol {

	// MARK: - TableAdapterProtocol Conformance -

	public var modelType: Any.Type = Model.self
	public var modelCellType: Any.Type = Cell.self

	// MARK: - Public Properties -

	/// Events you can observe from the adapter.
	public let events = EventsSubscriber()

	// MARK: - Initialization -
	
	public init(_ configuration: ((TableAdapter) -> ())? = nil) {
		configuration?(self)
	}

	// MARK: - Adapter Helpers Functions -

	public func dequeueCell(inTable table: UITableView, at indexPath: IndexPath?) -> UITableViewCell {
		guard let indexPath = indexPath else {
			let castedCell = Cell.reusableViewClass as! UITableViewCell.Type
			let cellInstance = castedCell.init()
			return cellInstance
		}
		return table.dequeueReusableCell(withIdentifier: Cell.reusableViewIdentifier, for: indexPath)
	}

	public func registerReusableCellViewForDirector(_ director: TableDirector) -> Bool {
		let id = Cell.reusableViewIdentifier
		guard director.cellReuseIDs.contains(id) == false else {
			return false
		}
		Cell.registerReusableView(inTable: director.table, as: .cell)
		director.cellReuseIDs.insert(id)
		return true
	}


	// MARK: - Supporting Functions -

	@discardableResult
	public func dispatchEvent(_ kind: TableAdapterEventID, model: Any?, cell: ReusableViewProtocol?, path: IndexPath?, params: Any?...) -> Any? {
		switch kind {
		case .dequeue:
			events.dequeue?(TableAdapter.Event(item: model, cell: cell, indexPath: path))

		case .rowHeight:
			return events.rowHeight?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .rowHeightEstimated:
			return events.rowHeightEstimated?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .canEditRow:
			return events.canEditRow?(TableAdapter.Event(item: model, cell: cell, indexPath: path))

		case .commitEdit:
			return events.commitEdit?(TableAdapter.Event(item: model, cell: cell, indexPath: path), params.first as! UITableViewCell.EditingStyle)
			
		case .editActions:
			return events.editActions?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .canMoveRow:
			return events.canMoveRow?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .moveRow:
			events.moveRow?(TableAdapter.Event(item: model, cell: cell, indexPath: path), params.first as! IndexPath)
			
		case .indentLevel:
			return events.indentLevel?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .prefetch:
			events.prefetch?(model as! [Model], params.first as! [IndexPath])
			
		case .cancelPrefetch:
			events.cancelPrefetch?(model as! [Model], params.first as! [IndexPath])
			
		case .willDisplay:
			events.willDisplay?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .shouldSpringLoad:
			return events.shouldSpringLoad?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .tapOnAccessory:
			events.tapOnAccessory?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .willSelect:
			return events.willSelect?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .tap:
			return events.didSelect?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .willDeselect:
			return events.willDeselect?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .didDeselect:
			return events.didDeselect?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .willBeginEdit:
			return events.willBeginEdit?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .didEndEdit:
			events.didEndEdit?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .editStyle:
			return events.editStyle?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .deleteConfirmTitle:
			return events.deleteConfirmTitle?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .editShouldIndent:
			return events.editShouldIndent?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .moveAdjustDestination:
			return events.moveAdjustDestination?(TableAdapter.Event(item: model, cell: cell, indexPath: path),
			params.first as! IndexPath)
			
		case .endDisplay:
			return events.endDisplay?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .shouldShowMenu:
			return events.shouldShowMenu?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .canPerformMenuAction:
			return events.canPerformMenuAction?(TableAdapter.Event(item: model, cell: cell, indexPath: path),
												params.first as! Selector,
												params.last as Any)
			
		case .performMenuAction:
			events.performMenuAction?(TableAdapter.Event(item: model, cell: cell, indexPath: path),
									  params.first as! Selector,
									  params.last as Any)

			
		case .shouldHighlight:
			return events.shouldHighlight?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .didHighlight:
			events.didHighlight?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .didUnhighlight:
			events.didUnhighlight?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .canFocus:
			return events.canFocus?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			
		case .leadingSwipeActions:
			if #available(iOS 11, *) {
				return events.leadingSwipeActions?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			}
			
		case .trailingSwipeActions:
			if #available(iOS 11, *) {
				return events.trailingSwipeActions?(TableAdapter.Event(item: model, cell: cell, indexPath: path))
			}

		}

		return nil
	}

}

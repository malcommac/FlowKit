//
//  CollectionAdapter.swift
//  FlowKit2
//
//  Created by dan on 26/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

public class CollectionCellAdapter<Model: ElementRepresentable, Cell: ReusableViewProtocol>: CollectionCellAdapterProtocol {

	// MARK: - CollectionCellAdapterProtocol Conformance -

	public var modelType: Any.Type = Model.self
	public var modelCellType: Any.Type = Cell.self

	// MARK: - Public Functions -

	public var events = CollectionCellAdapter.EventsSubscriber()

    // MARK: - Initializer -
    
    public init(_ configuration: ((CollectionCellAdapter) -> Void)? = nil) {
        configuration?(self)
    }
    
	// MARK: - Adapter Helpers Functions -

	public func dequeueCell(inCollection collection: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
		return collection.dequeueReusableCell(withReuseIdentifier: Cell.reusableViewIdentifier, for: indexPath)
	}

	public func registerReusableCellViewForDirector(_ director: CollectionDirector) -> Bool {
		let id = Cell.reusableViewIdentifier
		guard director.cellReuseIDs.contains(id) == false else {
			return false
		}
		Cell.registerReusableView(inCollection: director.collection, as: .cell)
		director.cellReuseIDs.insert(id)
		return true
	}

	public func dispatchEvent(_ kind: CollectionAdapterEventID, model: Any?, cell: ReusableViewProtocol?, path: IndexPath?, params: Any?...) -> Any? {
		switch kind {
		case .dequeue:
			events.dequeue?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .shouldSelect:
			return events.shouldSelect?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .shouldDeselect:
			return events.shouldDeselect?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .didSelect:
			events.didSelect?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .didDeselect:
			events.didDeselect?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .didHighlight:
			events.didHighlight?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .didUnhighlight:
			events.didUnhighlight?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .shouldHighlight:
			return events.shouldHighlight?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .willDisplay:
			events.willDisplay?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .endDisplay:
			events.endDisplay?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .shouldShowEditMenu:
			return events.shouldShowEditMenu?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .canPerformEditAction:
			return events.canPerformEditAction?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .performEditAction:
			return events.performEditAction?(CollectionCellAdapter.Event(element: model, cell: cell, path: path),
				params.first as! Selector,
				params.last as Any)

		case .canFocus:
			return events.canFocus?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .itemSize:
			return events.itemSize?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))

		case .prefetch:
			events.prefetch?(params.first as! [Model], params.last as! [IndexPath])

		case .cancelPrefetch:
			events.cancelPrefetch?(params.first as! [Model], params.last as! [IndexPath])

		case .shouldSpringLoad:
			return events.shouldSpringLoad?(CollectionCellAdapter.Event(element: model, cell: cell, path: path))
			
		}

		return nil
	}
}

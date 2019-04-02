//
//  CollectionAdapter.swift
//  FlowKit2
//
//  Created by dan on 26/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

public class CollectionAdapter<Model: ElementRepresentable, Cell: ReusableViewProtocol>: CollectionAdapterProtocol {

	// MARK: - TableAdapterProtocol Conformance -

	public var modelType: Any.Type = Model.self
	public var modelCellType: Any.Type = Cell.self

	// MARK: - Public Functions -

	public var events = CollectionAdapter.EventsSubscriber()

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
			events.dequeue?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .shouldSelect:
			return events.shouldSelect?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .shouldDeselect:
			return events.shouldDeselect?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .didSelect:
			events.didSelect?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .didDeselect:
			events.didDeselect?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .didHighlight:
			events.didHighlight?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .didUnhighlight:
			events.didUnhighlight?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .shouldHighlight:
			return events.shouldHighlight?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .willDisplay:
			events.willDisplay?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .endDisplay:
			events.endDisplay?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .shouldShowEditMenu:
			return events.shouldShowEditMenu?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .canPerformEditAction:
			return events.canPerformEditAction?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .performEditAction:
			return events.performEditAction?(CollectionAdapter.Event(model: model, cell: cell, path: path),
				params.first as! Selector,
				params.last as Any)

		case .canFocus:
			return events.canFocus?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .itemSize:
			return events.itemSize?(CollectionAdapter.Event(model: model, cell: cell, path: path))

		case .prefetch:
			events.prefetch?(params.first as! [Model], params.last as! [IndexPath])

		case .cancelPrefetch:
			events.cancelPrefetch?(params.first as! [Model], params.last as! [IndexPath])

		case .shouldSpringLoad:
			return events.shouldSpringLoad?(CollectionAdapter.Event(model: model, cell: cell, path: path))
			
		}

		return nil
	}
}

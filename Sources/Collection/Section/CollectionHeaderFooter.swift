//
//  CollectionHeaderFooter.swift
//  FlowKit2
//
//  Created by dan on 26/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

open class CollectionHeaderFooter<View: ReusableViewProtocol>: CollectionSectionHeaderFooterProtocol {

	// MARK: - Public Properties -

	/// Related section for this header/footer.
	public var section: CollectionSection?

	/// Events you can subscribe for header/footer instances.
	public var events = CollectionHeaderFooter.EventsSubscriber()

	// MARK: - CollectionSectionHeaderFooterProtocol Conformance -

	@discardableResult
	public func registerHeaderFooterViewForDirector(_ director: CollectionDirector, type: String) -> String {
		let identifier = View.reusableViewIdentifier
		if 	(type == UICollectionView.elementKindSectionHeader && director.headerReuseIDs.contains(identifier)) ||
			(type == UICollectionView.elementKindSectionFooter && director.footerReuseIDs.contains(identifier)) {
			return identifier
		}

		let collection = director.collection
		switch View.reusableViewSource {
		case .fromStoryboard:
			fatalError("Cannot use storyboard to instantiate \(type): \(View.reusableViewClass)")

		case .fromXib(let name, let bundle):
			let nib = UINib(nibName: name ?? identifier, bundle: bundle)
			collection?.register(nib, forSupplementaryViewOfKind: type, withReuseIdentifier: identifier)

		case .fromClass:
			collection?.register(View.reusableViewClass, forSupplementaryViewOfKind: type, withReuseIdentifier: identifier)

		}

		return identifier
	}

	public func dispatch(_ event: CollectionSectionEvents, isHeader: Bool, view: UIView?, section: Int) -> Any? {
		switch event {
		case .dequeue:
			events.dequeue?(CollectionHeaderFooter.Event(isHeader: isHeader, view: view, at: section))

		case .referenceSize:
			return events.referenceSize?(CollectionHeaderFooter.Event(isHeader: isHeader, view: view, at: section))

		case .didDisplay:
			events.didDisplay?(CollectionHeaderFooter.Event(isHeader: isHeader, view: view, at: section))

		case .endDisplay:
			events.endDisplay?(CollectionHeaderFooter.Event(isHeader: isHeader, view: view, at: section))

		case .willDisplay:
			events.willDisplay?(CollectionHeaderFooter.Event(isHeader: isHeader, view: view, at: section))
			
		}
		return nil
	}

}


//
//  TableSectionHeaderFooter.swift
//  FlowKit2
//
//  Created by dan on 08/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

// This class is used to setup the header/footer view based instance for a table's section.
open class TableSectionHeaderFooter<View: ReusableViewProtocol>: TableSectionHeaderFooterProtocol {

	//MARK: - Private Properties -

	// Associated section.
	public internal(set) weak var section: TableSection?

	//MARK: - Public Properties -

	// Events you can assign to monitor the header/footer of a section.
	public var events = TableSection.HeaderFooterEventsSubscriber<View>()

	//MARK: - Initialization -

	public init(_ configuration: ((TableSectionHeaderFooter) -> ())? = nil) {
		configuration?(self)
	}

	//MARK: - TableSectionHeaderFooterProtocol Conformances -

	public func registerHeaderFooterViewForDirector(_ director: TableDirector) -> String {
		let id = View.reusableViewIdentifier
		guard director.headerFooterReuseIdentifiers.contains(id) == false else {
			return id
		}
		View.registerReusableView(inTable: director.table, as: .header) // or footer, it's the same for table
		return id
	}

	@discardableResult
	public func dispatch(_ event: TableSectionEvents, isHeader: Bool, view: UIView?, section: Int, table: UITableView) -> Any? {
		switch event {
		case .dequeue:
			events.dequeue?(TableSection.HeaderFooterEvent<View>(header: isHeader, view: view, at: section))

		case .headerHeight:
			return events.height?(TableSection.HeaderFooterEvent<View>(header: true, view: view, at: section))

		case .footerHeight:
			return events.height?(TableSection.HeaderFooterEvent<View>(header: false, view: view, at: section))

		case .estHeaderHeight:
			return events.estimatedHeight?(TableSection.HeaderFooterEvent<View>(header: true, view: view, at: section))

		case .estFooterHeight:
			return events.estimatedHeight?(TableSection.HeaderFooterEvent<View>(header: false, view: view, at: section))

		case .endDisplay:
			events.endDisplay?(TableSection.HeaderFooterEvent<View>(header: false, view: view, at: section))

		case .willDisplay:
			events.willDisplay?(TableSection.HeaderFooterEvent<View>(header: false, view: view, at: section))

		}
		return nil
	}
	
}

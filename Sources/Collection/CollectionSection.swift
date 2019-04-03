//
//  CollectionSection.swift
//  FlowKit2
//
//  Created by dan on 26/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

/// Represent a single section of the collection.
open class CollectionSection: Equatable, Copying, DifferentiableSection {

	// MARK: - Public Properties -

	/// Identifier of the section
	public let identifier: String

	/// Items inside the collection
	public private(set) var elements: [ElementRepresentable]

	/// View of the header. It overrides any set value for `headerTitle`.
	public var headerView: CollectionHeaderFooterAdapterProtocol?

	/// View of the footer. It overrides any set value for `footerView`.
	public var footerView: CollectionHeaderFooterAdapterProtocol?

	// MARK: - Differentiable/Equatable Conformances -

	public static func == (lhs: CollectionSection, rhs: CollectionSection) -> Bool {
		return lhs.identifier == rhs.identifier
	}

	public var differenceIdentifier: String {
		return self.identifier
	}

	public func isContentEqual(to other: Differentiable) -> Bool {
		guard let other = other as? TableSection,
			elements.count == other.elements.count else {
				return false
		}
		for item in elements.enumerated() {
			if item.element.isContentEqual(to: other.elements[item.offset]) == false {
				return false
			}
		}
		return true
	}

	// MARK: - FlowLayout Properties -

	/// Implement this method when you want to provide margins for sections in the flow layout.
	/// If you do not implement this method, the margins are obtained from the properties of the flow layout object.
	/// NOTE: It's valid only for flow layout.
	open var sectionInsets: (() -> (UIEdgeInsets))? = nil

	/// The minimum spacing (in points) to use between items in the same row or column.
	/// If you do not implement this method, value is obtained from the properties of the flow layout object.
	/// NOTE: It's valid only for flow layout.
	open var minimumInterItemSpacing: (() -> (CGFloat))? = nil

	/// The minimum spacing (in points) to use between rows or columns.
	/// If you do not implement this method, value is obtained from the properties of the flow layout object.
	/// NOTE: It's valid only for flow layout.
	open var minimumLineSpacing: (() -> (CGFloat))? = nil

	// MARK: - Initialization -

	public required init(original: CollectionSection) {
		self.elements = original.elements
		self.identifier = original.identifier

		self.headerView = original.headerView
		self.footerView = original.footerView
	}

	public required init<C>(source: CollectionSection, elements: C) where C : Collection, C.Element == ElementRepresentable {
		self.elements = Array(elements)
		self.identifier = source.identifier
		
		self.headerView = source.headerView
		self.footerView = source.footerView
	}

	public init(id: String? = nil, elements: [ElementRepresentable] = []) {
		self.elements = elements
		self.identifier = id ?? UUID().uuidString
	}

	public convenience init(id: String? = nil, elements: [ElementRepresentable] = [],
							header: CollectionHeaderFooterAdapterProtocol?, footer: CollectionHeaderFooterAdapterProtocol?) {
		self.init(id: id, elements: elements)
		self.headerView = header
		self.footerView = footer
	}

}


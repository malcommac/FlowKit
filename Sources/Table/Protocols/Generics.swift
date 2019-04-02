//
//  ModelRepresentable.swift
//  FlowKit2
//
//  Created by dan on 04/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import Foundation

// MARK: - Copying -

protocol Copying {
	init(original: Self)
}

extension Copying {
	func copy() -> Self {
		return Self.init(original: self)
	}
}

// MARK: - Differentiable -

public protocol Differentiable {
	var differenceIdentifier: String { get }
	func isContentEqual(to other: Differentiable) -> Bool
}

// MARK: - ElementRepresentable -

public protocol ElementRepresentable: Differentiable {

	var modelClassIdentifier: String { get }

}

public extension ElementRepresentable {

	var modelClassIdentifier: String {
		return String(describing: type(of: self))
	}

}

// MARK: - DifferentiableSection -

public  protocol DifferentiableSection: Differentiable {
	var elements: [ElementRepresentable] { get }
	init<C: Swift.Collection>(source: Self, elements: C) where C.Element ==  ElementRepresentable
}

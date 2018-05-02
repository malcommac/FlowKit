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

/// No data shortcut when adapter does not need of a representable model
public struct NoData: ModelProtocol {
	public func isEqual(to other: ModelProtocol) -> Bool { return false }
	public var identifier: Int = 0
}

internal struct InternalContext {
	var model: ModelProtocol?
	var models: [ModelProtocol]?
	var path: IndexPath?
	var paths: [IndexPath]?
	var cell: CellProtocol?
	var container: Any
	var param1: Any?
	var param2: Any?
	var param3: Any?

	public init(_ model: ModelProtocol?, _ path: IndexPath, _ cell: CellProtocol?, _ scrollview: UIScrollView,
				param1: Any? = nil, param2: Any? = nil, param3: Any? = nil) {
		self.model = model
		self.path = path
		self.cell = cell
		self.container = scrollview
		self.param1 = param1
		self.param2 = param2
	}
	
	public init(_ models: [ModelProtocol], _ paths: [IndexPath], _ scrollview: UIScrollView) {
		self.models = models
		self.paths = paths
		self.container = scrollview
	}
}

public enum SectionType {
	case header
	case footer
}

///MARK: UIScrollViewDelegate Events

public struct ScrollViewEvents {
	var didScroll: ((UIScrollView) -> Void)? = nil
	var willBeginDragging: ((UIScrollView) -> Void)? = nil
	var willEndDragging: ((_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetOffset: UnsafeMutablePointer<CGPoint>) -> Void)? = nil
	var endDragging: ((_ scrollView: UIScrollView, _ willDecelerate: Bool) -> Void)? = nil
	var shouldScrollToTop: ((UIScrollView) -> Bool)? = nil
	var didScrollToTop: ((UIScrollView) -> Void)? = nil
	var willBeginDecelerating: ((UIScrollView) -> Void)? = nil
	var endDecelerating: ((UIScrollView) -> Void)? = nil
	var viewForZooming: ((UIScrollView) -> UIView?)? = nil
	var willBeginZooming: ((_ scrollView: UIScrollView, _ view: UIView?) -> Void)? = nil
	var endZooming: ((_ scrollView: UIScrollView, _ view: UIView?, _ scale: CGFloat) -> Void)? = nil
	var didZoom: ((UIScrollView) -> Void)? = nil
	var endScrollingAnimation: ((UIScrollView) -> Void)? = nil
	var didChangeAdjustedContentInset: ((UIScrollView) -> Void)? = nil
}

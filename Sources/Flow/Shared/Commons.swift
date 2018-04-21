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

internal struct InternalContext {
	var model: ModelProtocol?
	var models: [ModelProtocol]?
	var path: IndexPath?
	var paths: [IndexPath]?
	var cell: CellProtocol?
	var container: Any
	var param1: Any?
	var param2: Any?
	
	public init(_ model: ModelProtocol?, _ path: IndexPath, _ cell: CellProtocol?, _ scrollview: UIScrollView, param1: Any? = nil, param2: Any? = nil) {
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

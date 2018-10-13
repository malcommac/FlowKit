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

// MARK: - CollectionSection Events

public extension CollectionSectionView {
	
	public struct Event<T> {
		public typealias EventContext = Context<T>
		
		public var dequeue: ((EventContext) -> Void)? = nil
		public var referenceSize: ((EventContext) -> CGSize)? = nil
		public var didDisplay: ((EventContext) -> Void)? = nil
		public var endDisplay: ((EventContext) -> Void)? = nil
		public var willDisplay: ((EventContext) -> Void)? = nil

	}
	
}

// MARK: - CollectionAdapter Events
public extension CollectionAdapter {
	
	public struct Events<M,C> {
		public typealias EventContext = Context<M,C>
		
		public var dequeue: ((EventContext) -> Void)? = nil
		public var shouldSelect: ((EventContext) -> Bool)? = nil
		public var shouldDeselect: ((EventContext) -> Bool)? = nil
		public var didSelect: ((EventContext) -> Void)? = nil
		public var didDeselect: ((EventContext) -> Void)? = nil
		public var didHighlight: ((EventContext) -> Void)? = nil
		public var didUnhighlight: ((EventContext) -> Void)? = nil
		public var shouldHighlight: ((EventContext) -> Bool)? = nil
		public var willDisplay: ((_ cell: C, _ path: IndexPath) -> Void)? = nil
		public var endDisplay: ((_ cell: C, _ path: IndexPath) -> Void)? = nil
		public var shouldShowEditMenu: ((EventContext) -> Bool)? = nil
		public var canPerformEditAction: ((EventContext) -> Bool)? = nil
		public var performEditAction: ((_ ctx: EventContext, _ selector: Selector, _ sender: Any?) -> Void)? = nil
		public var canFocus: ((EventContext) -> Bool)? = nil
		public var itemSize: ((EventContext) -> CGSize)? = nil
		//var generateDragPreview: ((EventContext) -> UIDragPreviewParameters?)? = nil
		//var generateDropPreview: ((EventContext) -> UIDragPreviewParameters?)? = nil
		public var prefetch: ((_ items: [M], _ paths: [IndexPath], _ collection: UICollectionView) -> Void)? = nil
		public var cancelPrefetch: ((_ items: [M], _ paths: [IndexPath], _ collection: UICollectionView) -> Void)? = nil
		public var shouldSpringLoad: ((EventContext) -> Bool)? = nil
	}
	
}

// MARK: - CollectionDirector Events
public extension CollectionDirector {
	
	public struct Events {
		typealias HeaderFooterEvent = (view: UICollectionReusableView, path: IndexPath, table: UICollectionView)

		var layoutDidChange: ((_ old: UICollectionViewLayout, _ new: UICollectionViewLayout) -> UICollectionViewTransitionLayout?)? = nil
		var targetOffset: ((_ proposedContentOffset: CGPoint) -> CGPoint)? = nil
		var moveItemPath: ((_ originalIndexPath: IndexPath, _ proposedIndexPath: IndexPath) -> IndexPath)? = nil
        
        private var _shouldUpdateFocus: ((_ context: AnyObject) -> Bool)? = nil
        @available(iOS 9.0, *)
        var shouldUpdateFocus: ((_ context: UICollectionViewFocusUpdateContext) -> Bool)? {
            get { return _shouldUpdateFocus }
            set { _shouldUpdateFocus = newValue as? ((AnyObject) -> Bool) }
        }
        
        private var _didUpdateFocus: ((_ context: AnyObject, _ coordinator: AnyObject) -> Void)? = nil
        @available(iOS 9.0, *)
        var didUpdateFocus: ((_ context: UICollectionViewFocusUpdateContext, _ coordinator: UIFocusAnimationCoordinator) -> Void)? {
            get { return _didUpdateFocus }
            set { _didUpdateFocus = newValue as? ((AnyObject, AnyObject) -> Void) }
        }
		
		var willDisplayHeader : ((HeaderFooterEvent) -> Void)? = nil
		var willDisplayFooter : ((HeaderFooterEvent) -> Void)? = nil
		
		var endDisplayHeader : ((HeaderFooterEvent) -> Void)? = nil
		var endDisplayFooter : ((HeaderFooterEvent) -> Void)? = nil
	}
	
}

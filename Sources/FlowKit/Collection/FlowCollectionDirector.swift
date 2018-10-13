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

open class FlowCollectionDirector: CollectionDirector, UICollectionViewDelegateFlowLayout {
	
	/// Margins to apply to content.
	/// This is a global value, you can customize a per-section behaviour by implementing `sectionInsets` property into a section.
	/// Initially is set to `.zero`.
	public var sectionsInsets: UIEdgeInsets {
		set { self.layout?.sectionInset = newValue }
		get { return self.layout!.sectionInset }
	}
	
	/// Minimum spacing (in points) to use between items in the same row or column.
	/// This is a global value, you can customize a per-section behaviour by implementing `minimumInteritemSpacing` property into a section.
	/// Initially is set to `CGFloat.leastNormalMagnitude`.
	public var minimumInteritemSpacing: CGFloat {
		set { self.layout?.minimumInteritemSpacing = newValue }
		get { return self.layout!.minimumInteritemSpacing }
	}
	
	/// The minimum spacing (in points) to use between rows or columns.
	/// This is a global value, you can customize a per-section behaviour by implementing `minimumInteritemSpacing` property into a section.
	/// Initially is set to `0`.
	public var minimumLineSpacing: CGFloat {
		set { self.layout?.minimumLineSpacing = newValue }
		get { return self.layout!.minimumLineSpacing }
	}
	
	/// When this property is true, section header views scroll with content until they reach the top of the screen,
	/// at which point they are pinned to the upper bounds of the collection view.
	/// Each new header view that scrolls to the top of the screen pushes the previously pinned header view offscreen.
	///
	/// The default value of this property is `false`.
    @available(iOS 9.0, *)
	public var stickyHeaders: Bool {
		set { self.layout?.sectionHeadersPinToVisibleBounds = newValue }
		get { return (self.layout?.sectionHeadersPinToVisibleBounds ?? false) }
	}
	
	/// When this property is true, section footer views scroll with content until they reach the bottom of the screen,
	/// at which point they are pinned to the lower bounds of the collection view.
	/// Each new footer view that scrolls to the bottom of the screen pushes the previously pinned footer view offscreen.
	///
	/// The default value of this property is `false`.
    @available(iOS 9.0, *)
	public var stickyFooters: Bool {
		set { self.layout?.sectionFootersPinToVisibleBounds = newValue }
		get { return (self.layout?.sectionFootersPinToVisibleBounds ?? false) }
	}
	
	/// Return/set the `UICollectionViewFlowLayout` associated with the collection.
	public var layout: UICollectionViewFlowLayout? {
		get { return (self.collection?.collectionViewLayout as? UICollectionViewFlowLayout) }
		set {
			guard let c = newValue else { return }
			self.collection?.collectionViewLayout = c
		}
	}
	
	/// Set the section reference starting point.
	@available(iOS 11.0, *)
    public var sectionInsetReference: UICollectionViewFlowLayout.SectionInsetReference {
		set { self.layout?.sectionInsetReference = newValue }
		get { return self.layout!.sectionInsetReference }
	}
	
	/// Initialize a new flow collection manager.
	/// Note: Layout of the collection must be a UICollectionViewFlowLayout or subclass.
	///
	/// - Parameters:
	///   - collection: collection instance to manage.
	///   - flowLayout: if not `nil` it will be set a `collectionViewLayout` of given collection.
	public init(_ collection: UICollectionView, flowLayout: UICollectionViewLayout? = nil) {
		let usedLayout = (flowLayout ?? collection.collectionViewLayout)
		guard usedLayout is UICollectionViewFlowLayout else {
			fatalError("FlowCollectionManager require a UICollectionViewLayout layout.")
		}
		if let newLayout = flowLayout {
			collection.collectionViewLayout = newLayout
		}
		super.init(collection)

		self.layout?.sectionInset = .zero
		self.layout?.minimumInteritemSpacing = CGFloat.leastNormalMagnitude
		self.layout?.minimumLineSpacing = 0
	}
	
	//MARK: UICollectionViewDelegateFlowLayout Events
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let (model,adapter) = self.context(forItemAt: indexPath)
		switch self.itemSize {
		case .default:
			guard let size = adapter.dispatch(.itemSize, context: InternalContext(model, indexPath, nil, collectionView)) as? CGSize else {
				return self.layout!.itemSize
			}
			return size
		case .autoLayout(let est):
			return est
		case .fixed(let size):
			return size
		}
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		guard let value = self.sections[section].sectionInsets?() else {
			return self.sectionsInsets
		}
		return value
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		guard let value = self.sections[section].minimumInterItemSpacing?() else {
			return self.minimumInteritemSpacing
		}
		return value
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		guard let value = self.sections[section].minimumLineSpacing?() else {
			return self.minimumLineSpacing
		}
		return value
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		let header = (sections[section].header as? AbstractCollectionHeaderFooterItem)
		guard let size = header?.dispatch(.referenceSize, type: .header, view: nil, section: section, collection: collectionView) as? CGSize else {
			return .zero
		}
		return size
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		let footer = (sections[section].footer as? AbstractCollectionHeaderFooterItem)
		guard let size = footer?.dispatch(.referenceSize, type: .footer, view: nil, section: section, collection: collectionView) as? CGSize else {
			return .zero
		}
		return size
	}
	
}

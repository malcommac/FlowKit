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

open class CollectionDirector: NSObject,
UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
	
	/// Define the cell size.
	///
	/// - `default`: standard behaviour (no auto sizing, needs to implement `onGetItemSize` on adapters).
	/// - estimated: uses autolayout to calculate the size of the cell. You can provide an
	///				 estimated size of the cell to speed up the calculation.
	///				 Implement preferredLayoutAttributesFitting(_:) method in your cell to evaluate the size.
	/// - fixed: fixed size where each item has the same size
	public enum ItemSize {
		case `default`
		case autoLayout(estimated: CGSize)
		case fixed(size: CGSize)
	}
	
	//MARK: PUBLIC PROPERTIES
	
	/// Managed collection view
	public private(set) weak var collection: UICollectionView?
	
	/// Registered adapters for this collection manager
	public private(set) var adapters: [String: AbstractAdapterProtocol] = [:]
	
	/// Registered cell, header/footer identifiers for given collection view.
	public private(set) var reusableRegister: ReusableRegister
	
	/// Drag & Drop Event Manager
	/// Its valid only if `dragDropEnabled` is `true`.
	//public private(set) var dragDrop: DragAndDropManager? = nil
	
	/// Enable or disable drag&drop on collection view.
	/// You must configure the `dragDrop` manager if you enabled this feature.
	/*@available(iOS 11.0, *)
	public var dragDropEnabled: Bool {
		set {
			switch newValue {
			case true: 	self.dragDrop = DragAndDropManager(manager: self)
			case false: self.dragDrop = nil
			}
		}
		get { return (self.dragDrop != nil) }
	}*/
	
	/// Set it to `true` to enable cell prefetching. By default is set to `false`.
	public var prefetchEnabled: Bool {
		set {
			if #available(iOS 10.0, *) {
				switch newValue {
				case true: self.collection!.prefetchDataSource = self
				case false: self.collection!.prefetchDataSource = nil
				}
			} else {
				debugPrint("Prefetch is available only from iOS 10")
			}
		}
		get {
			if #available(iOS 10.0, *) {
				return (self.collection!.prefetchDataSource != nil)
			} else {
				debugPrint("Prefetch is available only from iOS 10")
				return false
			}
		}
	}

	/// Sections of the collection
	public private(set) var sections: [CollectionSection] = []
	
	/// Events of the collection
	public var on = CollectionDirector.Events()
	
	/// Events for UIScrollViewDelegate
	public var onScroll: ScrollViewEvents? = ScrollViewEvents()
	
	/// Internal representation of the cell size
	private var _itemSize: ItemSize = .default

	/// Define the size of the items into the cell (valid with `UICollectionViewFlowLayout` layout).
	public var itemSize: ItemSize {
		set {
			guard let layout = self.collection?.collectionViewLayout as? UICollectionViewFlowLayout else {
				return
			}
			self._itemSize = newValue
			switch _itemSize {
			case .autoLayout(let estimateSize):
				layout.estimatedItemSize = estimateSize
				layout.itemSize = CGSize(width: 50.0, height: 50.0) // default
			case .fixed(let fixedSize):
				layout.estimatedItemSize = .zero
				layout.itemSize = fixedSize
			case .default:
				layout.estimatedItemSize = .zero
				layout.itemSize = CGSize(width: 50.0, height: 50.0) // default
			}
		}
		get {
			return _itemSize
		}
	}
	
	/// Initialize a new collection manager with given collection instance.
	///
	/// - Parameter collection: instance of the collection to manage.
	public init(_ collection: UICollectionView) {
		self.reusableRegister = ReusableRegister(collection)
		super.init()
		self.collection = collection
		self.collection?.dataSource = self
		self.collection?.delegate = self
		//self.collection?.dragDelegate = self.dragDrop
		//self.collection?.dropDelegate = self.dragDrop
	}
	
	//MARK: Public Methods
	
	/// Return item at path.
	///
	/// - Parameters:
	///   - indexPath: index path to retrive
	///   - safe: `true` to return nil if path is invalid, `false` to perform an unchecked retrive.
	/// - Returns: model
	public func item(at indexPath: IndexPath, safe: Bool = true) -> ModelProtocol? {
		guard safe else { return self.sections[indexPath.section].models[indexPath.item] }
		
		guard indexPath.section < self.sections.count else { return nil }
		let section = self.sections[indexPath.section]
		
		guard indexPath.item < section.models.count else { return nil }
		return section.models[indexPath.item]
	}
	
	/// Reload collection.
	///
	/// - Parameter after: 	if defined a block animation is performed considering changes applied to the model;
	///						if `nil` reload is performed without animation.
	public func reloadData(after task: (() -> (Void))? = nil, onEnd: (() -> (Void))? = nil) {
		guard let task = task else {
			self.collection?.reloadData()
			onEnd?()
			return
		}
		
		// Keep a reference to removed items in order to perform diff and animation
		let oldSections: [CollectionSection] = Array.init(self.sections)
		var oldItemsInSections: [String: [ModelProtocol]] = [:]
		self.sections.forEach { oldItemsInSections[$0.UUID] = Array($0.models) }
		
		// Execute block for changes
		task()
		
		// Evaluate changes in sections
		let sectionChanges = SectionChanges.fromCollectionSections(old: oldSections, new: self.sections)

		self.collection?.performBatchUpdates({
			sectionChanges.applyChanges(toCollection: self.collection)
			
			// For any remaining active section evaluate changes inside
			self.sections.enumerated().forEach { (idx,newSection) in
				if let oldSectionItems = oldItemsInSections[newSection.UUID] {
					let diffData = diff(old: oldSectionItems, new: newSection.models)
					let itemChanges = SectionItemsChanges.create(fromChanges: diffData, section: idx)
					itemChanges.applyChangesToSectionItems(of: collection)
				}
			}
			
		}, completion: { end in
			if end { onEnd?() }
		})
	}
	
	
	/// Register an adapter.
	/// An adapter is an object which manage a pair of `AnyHashable`, `CellProtocol` types which defines
	/// a type of data inside the collection (all models of the given type are managed by given cell type).
	/// This is used to ensure type safety of the data and its the core of the library itself.
	/// Be sure to register all required adapters before using the collection itself.
	///
	/// - Parameter adapter: adapter to register
	public func register(adapter: AbstractAdapterProtocol) {
		let modelID = String(describing: adapter.modelType)
		self.adapters[modelID] = adapter // register adapter
		self.reusableRegister.registerCell(forAdapter: adapter) // register associated cell types into the collection
	}
	
	/// Register multiple adapters for collection.
	///
	/// - Parameter adapters: adapters
	public func register(adapters: [AbstractAdapterProtocol]) {
		adapters.forEach { self.register(adapter: $0) }
	}
	
	//MARK: Manage Content
	
	/// Change the content of the table.
	///
	/// - Parameter models: array of models to set.
	public func set(sections: [CollectionSection]) {
		self.sections = sections
	}
	
	/// Create a new section, append it at the end of the sections list and insert in it passed models.
	///
	/// - Parameter models: models of the section
	/// - Returns: added section instance
	@discardableResult
	public func add(models: [ModelProtocol]) -> CollectionSection {
		let section = CollectionSection(models)
		self.sections.append(section)
		return section
	}
	
	/// Add a new section at given index.
	///
	/// - Parameters:
	///   - section: section to insert.
	///   - index: destination index; if `nil` it will be append at the end of the list.
	public func add(_ section: CollectionSection, at index: Int? = nil) {
		guard let i = index, i < self.sections.count else {
			self.sections.append(section)
			return
		}
		self.sections.insert(section, at: i)
	}
	
	/// Add a list of the section starting at given index.
	///
	/// - Parameters:
	///   - sections: sections to append
	///   - index: destination index; if `nil` it will be append at the end of the list.
	public func add(sections: [CollectionSection], at index: Int? = nil) {
		guard let i = index, i < self.sections.count else {
			self.sections.append(contentsOf: sections)
			return
		}
		self.sections.insert(contentsOf: sections, at: i)
	}
	
	/// Remove all sections from the collection.
	///
	/// - Returns: number of removed sections.
	@discardableResult
	public func removeAll(keepingCapacity kp: Bool = false) -> Int {
		let count = self.sections.count
		self.sections.removeAll(keepingCapacity: kp)
		return count
	}
	
	/// Remove section at index from the collection.
	/// If index is not valid it does nothing.
	///
	/// - Parameter index: index of the section to remove.
	/// - Returns: removed section
	@discardableResult
	public func remove(section index: Int) -> CollectionSection? {
		guard index < self.sections.count else { return nil }
		return self.sections.remove(at: index)
	}
	
	/// Remove sections at given indexes.
	/// Invalid indexes are ignored.
	///
	/// - Parameter indexes: indexes to remove.
	/// - Returns: removed sections.
	@discardableResult
	public func remove(sectionsAt indexes: IndexSet) -> [CollectionSection] {
		var removed: [CollectionSection] = []
		indexes.reversed().forEach {
			if $0 < self.sections.count {
				removed.append(self.sections.remove(at: $0))
			}
		}
		return removed
	}
	
	/// Get section at given index.
	///
	/// - Parameter index: index, if invalid produces `nil` result.
	/// - Returns: section instance if index is valid, `nil` otherwise.
	public func section(at index: Int) -> CollectionSection? {
		guard index < self.sections.count else { return nil }
		return self.sections[index]
	}
	
	/// Get the first section if exists.
	///
	/// - Returns: first section, `nil` if has no sections.
	public func firstSection() -> CollectionSection? {
		return self.sections.first
	}
	
	/// Get the last section if exists.
	///
	/// - Returns: last section, `nil` if has no sections.
	public func lastSection() -> CollectionSection? {
		return self.sections.last
	}
	
	//MARK: Helper Internal Methods
	
	/// Return the context for an element at given index.
	/// It returns the instance of the model and the registered adapter used to represent it.
	///
	/// - Parameter index: index path of the item.
	/// - Returns: context
	internal func context(forItemAt index: IndexPath) -> (ModelProtocol,AbstractAdapterProtocolFunctions) {
		let item: ModelProtocol = self.sections[index.section].models[index.row]
		let modelID = String(describing: type(of: item.self))
		guard let adapter = self.adapters[modelID] else {
			fatalError("Failed to found an adapter for \(modelID)")
		}
		return (item,adapter as! AbstractAdapterProtocolFunctions)
	}

	internal func context(forModel model: ModelProtocol) -> AbstractAdapterProtocolFunctions {
		let modelID = String(describing: type(of: item.self))
		guard let adapter = self.adapters[modelID] else {
			fatalError("Failed to found an adapter for \(modelID)")
		}
		return (adapter as! AbstractAdapterProtocolFunctions)
	}
	
	internal func adapters(forIndexPath paths: [IndexPath]) -> [PrefetchModelsGroup] {
		var list: [String: PrefetchModelsGroup] = [:]
		paths.forEach { indexPath in
			let model = self.sections[indexPath.section].models[indexPath.item]
			let modelID = String(describing: type(of: model.self))
			
			var context: PrefetchModelsGroup? = list[modelID]
			if context == nil {
				context = PrefetchModelsGroup(adapter: self.adapters[modelID] as! AbstractAdapterProtocolFunctions)
				list[modelID] = context
			}
			context!.models.append(model)
			context!.indexPaths.append(indexPath)
		}
		
		return Array(list.values)
	}
}

//MARK: CollectionManager UICollectionViewDataSource Protocol Implementation

public extension CollectionDirector {
	
	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return self.sections.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.sections[section].models.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let (model,adapter) = self.context(forItemAt: indexPath)
		let cell = adapter._instanceCell(in: collectionView, at: indexPath)
		adapter.dispatch(.dequeue, context: InternalContext.init(model, indexPath, cell, collectionView))
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.willDisplay, context: InternalContext.init(model, indexPath, cell, collectionView))
	}
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		self.adapters.forEach {
			($0.value as! AbstractAdapterProtocolFunctions).dispatch(.endDisplay, context: InternalContext.init(nil, indexPath, cell, collectionView))
		}
	}

	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didSelect, context: InternalContext.init(model, indexPath, nil, collectionView))
	}
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didDeselect, context: InternalContext.init(model, indexPath, nil, collectionView))
	}
	
	public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldSelect, context: InternalContext.init(model, indexPath, nil, collectionView)) as? Bool) ?? true)
	}
	
	public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldDeselect, context: InternalContext.init(model, indexPath, nil, collectionView)) as? Bool) ?? true)
	}
	
	public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldHighlight, context: InternalContext.init(model, indexPath, nil, collectionView)) as? Bool) ?? true)
	}
	
	func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didHighlight, context: InternalContext.init(model, indexPath, nil, collectionView))
	}
	
	func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didUnhighlight, context: InternalContext.init(model, indexPath, nil, collectionView))
	}
	
	public func collectionView(_ collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
		guard let layout = self.on.layoutDidChange?(fromLayout,toLayout) else {
			return UICollectionViewTransitionLayout.init(currentLayout: fromLayout, nextLayout: toLayout)
		}
		return layout
	}
	
	public func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
		guard let path = self.on.moveItemPath?(originalIndexPath,proposedIndexPath) else {
			return proposedIndexPath
		}
		return path
	}
	
	public func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
		guard let offset = self.on.targetOffset?(proposedContentOffset) else {
			return proposedContentOffset
		}
		return offset
	}
	
	public func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldShowEditMenu, context: InternalContext.init(model, indexPath, nil, collectionView)) as? Bool) ?? false)
	}
	
	public func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.canPerformEditAction, context: InternalContext.init(model, indexPath, nil, collectionView, param1: action, param2: sender)) as? Bool) ?? true)
	}
	
	public func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.performEditAction, context: InternalContext.init(model, indexPath, nil, collectionView, param1: action, param2: sender))
	}
	
	public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.canFocus, context: InternalContext.init(model, indexPath, nil, collectionView)) as? Bool) ?? true)
	}
	
	@available(iOS 11.0, *)
	public func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldSpringLoad, context: InternalContext.init(model, indexPath, nil, collectionView)) as? Bool) ?? true)
	}
	
    @available(iOS 9.0, *)
	public func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
		guard let update = self.on.shouldUpdateFocus?(context) else {
			return true
		}
		return update
	}
	
    @available(iOS 9.0, *)
	public func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		self.on.didUpdateFocus?(context,coordinator)
	}
	
	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		let section = sections[indexPath.section]
		
		var identifier: String!
		
		switch kind {
        case UICollectionView.elementKindSectionHeader:
			guard let header = section.header else { return UICollectionReusableView() }
			identifier = self.reusableRegister.registerHeaderFooter(header, type: kind)
			
        case UICollectionView.elementKindSectionFooter:
			guard let footer = section.footer else { return UICollectionReusableView() }
			identifier = self.reusableRegister.registerHeaderFooter(footer, type: kind)
			
		default:
			return UICollectionReusableView()
		}
		
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            _ = (section.header as? AbstractCollectionHeaderFooterItem)?.dispatch(.dequeue, type: .header, view: view, section: indexPath.section, collection: collectionView)
        case UICollectionView.elementKindSectionFooter:
            _ = (section.header as? AbstractCollectionHeaderFooterItem)?.dispatch(.dequeue, type: .footer, view: view, section: indexPath.section, collection: collectionView)
        default:
            break
        }

		return view
	}
	
	public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {

        guard indexPath.section < sections.count else { return }
		switch elementKind {
        case UICollectionView.elementKindSectionHeader:
			let header = (sections[indexPath.section].header as? AbstractCollectionHeaderFooterItem)
			let _ = header?.dispatch(.willDisplay, type: .header, view: view, section: indexPath.section, collection: collectionView)
			self.on.willDisplayHeader?( (view,indexPath,collectionView) )
        case UICollectionView.elementKindSectionFooter:
			let footer = (sections[indexPath.section].footer as? AbstractCollectionHeaderFooterItem)
			let _ = footer?.dispatch(.willDisplay, type: .footer, view: view, section: indexPath.section, collection: collectionView)
			self.on.willDisplayFooter?( (view,indexPath,collectionView) )
		default:
			break
		}
		view.layer.zPosition = 0
	}
	
	public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {

        guard indexPath.section < sections.count else { return }
		switch elementKind {
        case UICollectionView.elementKindSectionHeader:
			let header = (sections[indexPath.section].header as? AbstractCollectionHeaderFooterItem)
			let _ = header?.dispatch(.endDisplay, type: .header, view: view, section: indexPath.section, collection: collectionView)
			self.on.endDisplayHeader?( (view,indexPath,collectionView) )
        case UICollectionView.elementKindSectionFooter:
			let footer = (sections[indexPath.section].footer as? AbstractCollectionHeaderFooterItem)
			let _ = footer?.dispatch(.endDisplay, type: .footer, view: view, section: indexPath.section, collection: collectionView)
			self.on.endDisplayFooter?( (view,indexPath,collectionView) )
		default:
			break
		}
	}
	
	//MARK: Prefetching
	
	internal class PrefetchModelsGroup {
		let adapter: 	AbstractAdapterProtocolFunctions
		var models: 	[ModelProtocol] = []
		var indexPaths: [IndexPath] = []
		
		public init(adapter: AbstractAdapterProtocolFunctions) {
			self.adapter = adapter
		}
	}
	
	
	public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		self.adapters(forIndexPath: indexPaths).forEach {
			$0.adapter.dispatch(.prefetch, context: InternalContext.init($0.models, $0.indexPaths, collectionView))
		}
	}
	
	public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		self.adapters(forIndexPath: indexPaths).forEach {
			$0.adapter.dispatch(.cancelPrefetch, context: InternalContext.init($0.models, $0.indexPaths, collectionView))
		}
	}
	
}

// MARK: - UIScrollViewDelegate Events

public extension CollectionDirector {
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.onScroll?.didScroll?(scrollView)
	}
	
	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		self.onScroll?.willBeginDragging?(scrollView)
	}
	
	public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		self.onScroll?.willEndDragging?(scrollView,velocity,targetContentOffset)
	}
	
	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self.onScroll?.endDragging?(scrollView,decelerate)
	}
	
	public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		return (self.onScroll?.shouldScrollToTop?(scrollView) ?? true)
	}
	
	public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
		self.onScroll?.didScrollToTop?(scrollView)
	}
	
	public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		self.onScroll?.willBeginDecelerating?(scrollView)
	}
	
	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self.onScroll?.endDecelerating?(scrollView)
	}
	
	public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.onScroll?.viewForZooming?(scrollView)
	}
	
	public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
		self.onScroll?.willBeginZooming?(scrollView,view)
	}
	
	public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
		self.onScroll?.endZooming?(scrollView,view,scale)
	}
	
	public func scrollViewDidZoom(_ scrollView: UIScrollView) {
		self.onScroll?.didZoom?(scrollView)
	}
	
	public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		self.onScroll?.endScrollingAnimation?(scrollView)
	}
	
	public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
		self.onScroll?.didChangeAdjustedContentInset?(scrollView)
	}
	
}


public extension CollectionDirector {
	
	/// It keeps the status of the registration of both cell and header/footer reusable identifiers
	public class ReusableRegister {
		
		/// Managed collection
		public private(set) weak var collection: UICollectionView?
		
		/// Registered cell identifiers
		public private(set) var cellIDs: Set<String> = []
		
		/// Registered header identifiers
		public private(set) var headerIDs: Set<String> = []
		
		/// Registered footer identifiers
		public private(set) var footerIDs: Set<String> = []
		
		/// Initialize a new register manager for given collection.
		///
		/// - Parameter collection: collection instance
		internal init(_ collection: UICollectionView) {
			self.collection = collection
		}
		
		/// Register cell defined inside given adapter.
		/// If cell is already registered this operation does nothing.
		///
		/// - Parameter adapter: adapter to register
		@discardableResult
		internal func registerCell(forAdapter adapter: AbstractAdapterProtocol) -> Bool {
			let identifier = adapter.cellReuseIdentifier
			guard !cellIDs.contains(identifier) else {
				return false
			}
			let bundle = Bundle.init(for: adapter.cellClass)
			if let _ = bundle.path(forResource: identifier, ofType: "nib") {
				let nib = UINib(nibName: identifier, bundle: bundle)
				collection?.register(nib, forCellWithReuseIdentifier: identifier)
			} else if adapter.registerAsClass {
				collection?.register(adapter.cellClass, forCellWithReuseIdentifier: identifier)
			}
			cellIDs.insert(identifier)
			return true
		}
		
		/// Register header/footer identifier as needed.
		/// If already registered this operation does nothing.
		///
		/// - Parameters:
		///   - headerFooter: header/footer item to register
		///   - type: is it header or footer
		/// - Returns: registered identifier
		@discardableResult
		internal func registerHeaderFooter(_ headerFooter: CollectionSectionProtocol, type: String) -> String {
			let identifier = headerFooter.reuseIdentifier
            if 	(type == UICollectionView.elementKindSectionHeader && self.headerIDs.contains(identifier)) ||
                (type == UICollectionView.elementKindSectionFooter && self.footerIDs.contains(identifier)) {
				return identifier
			}
			
			let bundle = Bundle(for: headerFooter.viewClass)
			if let _ = bundle.path(forResource: identifier, ofType: "nib") {
				let nib = UINib(nibName: identifier, bundle: bundle)
				collection?.register(nib, forSupplementaryViewOfKind: type, withReuseIdentifier: identifier)
			} else if headerFooter.registerAsClass {
				collection?.register(headerFooter.viewClass, forSupplementaryViewOfKind: type, withReuseIdentifier: identifier)
			}
			return identifier
		}
		
	}
	
}


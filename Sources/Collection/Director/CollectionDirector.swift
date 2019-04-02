//
//  CollectionDirector.swift
//  FlowKit2
//
//  Created by dan on 26/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

open class CollectionDirector: NSObject,
	UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {

	//MARK: - Private Properties -

	/// Registered adapters for this collection manager
	internal var adapters = [String: CollectionAdapterProtocol]()

	/// Registered cell identifiers
	internal var cellReuseIDs = Set<String>()

	/// Registered header identifiers
	internal var headerReuseIDs = Set<String>()

	/// Registered footer identifiers
	internal var footerReuseIDs = Set<String>()

	//MARK: - Public Properties -

	/// Managed collection view
	public private(set) weak var collection: UICollectionView?

	/// Sections of the collection
	public private(set) var sections = [CollectionSection]()

	/// Events subscriber
	public var events = CollectionDirector.EventsSubscriber()

	/// ScrollView delegate events subscriber
	public var scrollEvents = ScrollViewEventsHandler()

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

	//MARK: - Initialization -

	/// Initialize a new collection manager with given collection instance.
	///
	/// - Parameter collection: instance of the collection to manage.
	public init(_ collection: UICollectionView) {
		super.init()
		self.collection = collection
		self.collection?.dataSource = self
		self.collection?.delegate = self
		//self.collection?.dragDelegate = self.dragDrop
		//self.collection?.dropDelegate = self.dragDrop
	}

	// MARK: - Register Adapters -

	/// Register a sequence of adapter for the table. If an adapter is already
	/// registered request will be ignored automatically.
	///
	/// - Parameter adapters: adapters to register.
	public func registerAdapters(_ adapters: [CollectionAdapterProtocol]) {
		adapters.forEach {
			registerAdapter($0)
		}
	}

	/// Register a new adapter for the table.
	/// An adapter rapresent the entity composed by the pair <model, cell>
	/// used by the directory to manage their representation inside the table itself.
	/// If adapter is already registered it will be ignored automatically.
	///
	/// - Parameter adapter: adapter instance to register.
	public func registerAdapter(_ adapter: CollectionAdapterProtocol) {
		guard adapters[adapter.modelIdentifier] == nil else {
			return
		}
		adapters[adapter.modelIdentifier] = adapter
		adapter.registerReusableCellViewForDirector(self)
	}

	// MARK: - Public Functions -

	/// Return element at given path. If index is invalid `nil` is returned.
	///
	/// - Parameters:
	///   - indexPath: index path to retrive
	///   - safe: `true` to return nil if path is invalid, `false` to perform an unchecked retrive.
	/// - Returns: model
	public func elementAt(_ indexPath: IndexPath) -> ElementRepresentable? {
		guard indexPath.section >= 0, indexPath.row >= 0,
			indexPath.section < self.sections.count,
			indexPath.row < sections[indexPath.section].elements.count else {
			return nil
		}
		return sections[indexPath.section].elements[indexPath.section]
	}

	/// Change the content of the table.
	///
	/// - Parameter models: array of models to set.
	public func set(sections newSections: [CollectionSection]) {
		sections = newSections
	}

	/// Create a new section, append it at the end of the sections list and insert in it passed models.
	///
	/// - Parameter models: models of the section
	/// - Returns: added section instance
	@discardableResult
	public func add(elements: [ElementRepresentable]) -> CollectionSection {
		let section = CollectionSection(elements: elements)
		sections.append(section)
		return section
	}

	/// Add a new section at given index.
	///
	/// - Parameters:
	///   - section: section to insert.
	///   - index: destination index; if `nil` it will be append at the end of the list.
	public func add(section: CollectionSection, at index: Int? = nil) {
		guard let index = index, index < sections.count else {
			sections.append(section)
			return
		}
		sections.insert(section, at: index)
	}

	/// Add a list of the section starting at given index.
	///
	/// - Parameters:
	///   - sections: sections to append
	///   - index: destination index; if `nil` it will be append at the end of the list.
	public func add(sections newSections: [CollectionSection], at index: Int? = nil) {
		guard let i = index, i < sections.count else {
			sections.append(contentsOf: newSections)
			return
		}
		sections.insert(contentsOf: newSections, at: i)
	}

	/// Remove all sections from the collection.
	///
	/// - Returns: number of removed sections.
	@discardableResult
	public func removeAll(keepingCapacity kp: Bool = false) -> Int {
		let count = sections.count
		sections.removeAll(keepingCapacity: kp)
		return count
	}

	/// Remove section at index from the collection.
	/// If index is not valid it does nothing.
	///
	/// - Parameter index: index of the section to remove.
	/// - Returns: removed section
	@discardableResult
	public func remove(section index: Int) -> CollectionSection? {
		guard index < sections.count else {
			return nil
		}
		return sections.remove(at: index)
	}

	/// Remove sections at given indexes.
	/// Invalid indexes are ignored.
	///
	/// - Parameter indexes: indexes to remove.
	/// - Returns: removed sections.
	@discardableResult
	public func remove(sectionsAt indexes: IndexSet) -> [CollectionSection] {
		var removed = [CollectionSection]()
		indexes.reversed().forEach {
			if $0 < self.sections.count {
				removed.append(sections.remove(at: $0))
			}
		}
		return removed
	}

	/// Get section at given index.
	///
	/// - Parameter index: index, if invalid produces `nil` result.
	/// - Returns: section instance if index is valid, `nil` otherwise.
	public func sectionAt(_ index: Int) -> CollectionSection? {
		guard index < sections.count else {
			return nil
		}
		return sections[index]
	}

	/// Get the first section if exists.
	///
	/// - Returns: first section, `nil` if has no sections.
	public func firstSection() -> CollectionSection? {
		return sections.first
	}

	/// Get the last section if exists.
	///
	/// - Returns: last section, `nil` if has no sections.
	public func lastSection() -> CollectionSection? {
		return sections.last
	}

	// MARK: - Private Methods -

	internal func context(forItemAt indexPath: IndexPath) -> (ElementRepresentable, CollectionAdapterProtocol) {
		let modelInstance = sections[indexPath.section].elements[indexPath.row]
		guard let adapter = adapters[modelInstance.modelClassIdentifier] else {
			fatalError("No register adapter for model '\(modelInstance.modelClassIdentifier)' at (\(indexPath.section),\(indexPath.row))")
		}
		return (modelInstance, adapter)
	}

}

public extension CollectionDirector {

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return sections.count
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return sections[section].elements.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let (model, adapter) = context(forItemAt: indexPath)
		let cell = adapter.dequeueCell(inCollection: collectionView, at: indexPath)
		adapter.dispatchEvent(.dequeue, model: model, cell: cell, path: indexPath, params: nil)
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let (model, adapter) = context(forItemAt: indexPath)
		adapter.dispatchEvent(.willDisplay, model: model, cell: cell, path: indexPath, params: nil)
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		// TODO
	}

	// MARK: - Select -

	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		let (model, adapter) = context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.didDeselect, model: model, cell: nil, path: indexPath, params: nil) as? Bool) ?? true
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let (model, adapter) = context(forItemAt: indexPath)
		adapter.dispatchEvent(.didSelect, model: model, cell: nil, path: indexPath, params: nil)
	}

	// MARK: - Deselect -

	func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
		let (model, adapter) = context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.shouldDeselect, model: model, cell: nil, path: indexPath, params: nil) as? Bool) ?? true
	}

	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		let (model, adapter) = context(forItemAt: indexPath)
		adapter.dispatchEvent(.didDeselect, model: model, cell: nil, path: indexPath, params: nil)
	}

	// MARK: - Highlight -

	func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
		let (model, adapter) = context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.didDeselect, model: model, cell: nil, path: indexPath, params: nil) as? Bool) ?? true
	}

	func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
		let (model, adapter) = context(forItemAt: indexPath)
		adapter.dispatchEvent(.didHighlight, model: model, cell: nil, path: indexPath, params: nil)
	}

	func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
		let (model, adapter) = context(forItemAt: indexPath)
		adapter.dispatchEvent(.didUnhighlight, model: model, cell: nil, path: indexPath, params: nil)
	}

	// MARK: - Layout -

	func collectionView(_ collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
		guard let layout = events.layoutDidChange?(fromLayout,toLayout) else {
			return UICollectionViewTransitionLayout.init(currentLayout: fromLayout, nextLayout: toLayout)
		}
		return layout
	}

	func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
		guard let path = events.moveItemPath?(originalIndexPath,proposedIndexPath) else {
			return proposedIndexPath
		}
		return path
	}

	func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
		guard let offset = events.targetOffset?(proposedContentOffset) else {
			return proposedContentOffset
		}
		return offset
	}

	// MARK: - Contextual Menu -

	func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
		let (model, adapter) = context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.shouldShowEditMenu, model: model, cell: nil, path: indexPath, params: nil) as? Bool) ?? false
	}

	// MARK: - Actions -

	func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
		let (model, adapter) = context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.canPerformEditAction, model: model, cell: nil, path: indexPath, params: action, sender) as? Bool) ?? true
	}

	func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
		let (model, adapter) = context(forItemAt: indexPath)
		adapter.dispatchEvent(.performEditAction, model: model, cell: nil, path: indexPath, params: action, sender)
	}

	// MARK: - Spring Load -

	@available(iOS 11.0, *)
	func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.shouldSpringLoad, model: model, cell: nil, path: indexPath, params: nil) as? Bool) ?? true
	}

	// MARK: - Focus -

	func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		let (model, adapter) = context(forItemAt: indexPath)
		return (adapter.dispatchEvent(.canFocus, model: model, cell: nil, path: indexPath, params: nil) as? Bool) ?? true
	}

	func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
		guard let update = events.shouldUpdateFocus?(context) else {
			return true
		}
		return update
	}

	func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		events.didUpdateFocus?(context, coordinator)
	}

	// MARK: - Header/Footer -

	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

		let headerFooterView: CollectionSectionHeaderFooterProtocol?
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			headerFooterView = sections[indexPath.section].headerView
		case UICollectionView.elementKindSectionFooter:
			headerFooterView = sections[indexPath.section].footerView
		default:
			return UICollectionReusableView()
		}

		if headerFooterView == nil {
			return UICollectionReusableView()
		}

		let id = headerFooterView!.registerHeaderFooterViewForDirector(self, type: kind)
		return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: id, for: indexPath)
	}

	func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
		let headerFooterView = headerFooterForSection(ofType: elementKind, at: indexPath)
		let _ = headerFooterView?.dispatch(.willDisplay, isHeader: true, view: view, section: indexPath.section)
		view.layer.zPosition = 0
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
		let headerFooterView = headerFooterForSection(ofType: elementKind, at: indexPath)
		let _ = headerFooterView?.dispatch(.endDisplay, isHeader: true, view: view, section: indexPath.section)
	}

	func headerFooterForSection(ofType type: String, at indexPath: IndexPath) -> CollectionSectionHeaderFooterProtocol? {
		switch type {
		case UICollectionView.elementKindSectionHeader:
			return sections[indexPath.section].headerView
		case UICollectionView.elementKindSectionFooter:
			return sections[indexPath.section].footerView
		default:
			return nil
		}
	}

	// MARK: - Prefetch -

	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		adaptersForIndexPaths(indexPaths).forEach {
			$0.adapter.dispatchEvent(.prefetch, model: nil, cell: nil, path: nil, params: $0.models, $0.indexPaths)
		}
	}

	func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		adaptersForIndexPaths(indexPaths).forEach {
			$0.adapter.dispatchEvent(.cancelPrefetch, model: nil, cell: nil, path: nil, params: $0.models, $0.indexPaths)
		}
	}

	// MARK: - Private Functions -

	internal func adaptersForIndexPaths(_ paths: [IndexPath]) -> [PrefetchModelsGroup] {
		let result = paths.reduce(into: [String: PrefetchModelsGroup]()) { (result, indexPath) in
			let model = sections[indexPath.section].elements[indexPath.item]

			var context = result[model.modelClassIdentifier]
			if context == nil {
				guard let adapter = adapters[model.modelClassIdentifier] else {
					fatalError("Failed to get adapter for model: '\(model)' at (\(indexPath.section),\(indexPath.row))")
				}
				context = PrefetchModelsGroup(adapter: adapter)
			}
			context?.models.append(model)
			context?.indexPaths.append(indexPath)
		}
		return Array(result.values)
	}

	// MARK: - ScrollView Delegate -

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.scrollEvents.didScroll?(scrollView)
	}

	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		self.scrollEvents.willBeginDragging?(scrollView)
	}

	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		self.scrollEvents.willEndDragging?(scrollView,velocity,targetContentOffset)
	}

	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self.scrollEvents.endDragging?(scrollView,decelerate)
	}

	func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		return (self.scrollEvents.shouldScrollToTop?(scrollView) ?? true)
	}

	func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
		self.scrollEvents.didScrollToTop?(scrollView)
	}

	func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		self.scrollEvents.willBeginDecelerating?(scrollView)
	}

	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self.scrollEvents.endDecelerating?(scrollView)
	}

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.scrollEvents.viewForZooming?(scrollView)
	}

	func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
		self.scrollEvents.willBeginZooming?(scrollView,view)
	}

	func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
		self.scrollEvents.endZooming?(scrollView,view,scale)
	}

	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		self.scrollEvents.didZoom?(scrollView)
	}

	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		self.scrollEvents.endScrollingAnimation?(scrollView)
	}

	func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
		self.scrollEvents.didChangeAdjustedContentInset?(scrollView)
	}

}

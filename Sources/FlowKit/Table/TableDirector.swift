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

public class TableDirector: NSObject, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
	
	/// Height of the row
	///
	/// - `default`: both `rowHeight`,`estimatedRowHeight` are set to `UITableViewAutomaticDimension`
	/// - automatic: automatic using autolayout. You can provide a valid estimated value.
	/// - fixed: fixed value. If all of your cells are the same height set it to fixed in order to improve the performance of the table.
	public enum RowHeight {
		case `default`
		case autoLayout(estimated: CGFloat)
		case fixed(height: CGFloat)
	}
	
	/// Managed table view
	public private(set) weak var tableView: UITableView?

	/// Registered adapters for managed tables
	public private(set) var adapters: [String: AbstractAdapterProtocol] = [:]

	/// Registered cell reusable identifiers
	private var cellIDs: Set<String> = []
	
	/// Visible sections of the table
	public private(set) var sections: [TableSection] = []
	
	/// Registered header/footer's view reusable identifiers
	private var headersFootersIDs: Set<String> = []
	
	/// Height of headers into the table.
	/// This parameter maybe overriden by single TableSection's `headerHeight` event.
	public var headerHeight: CGFloat? = nil
	
	/// Height of footers into the table.
	/// This parameter maybe overriden by single TableSection's `footerHeight` event.
	public var footerHeight: CGFloat? = nil
	
	/// Events of the table
	public var on = TableDirector.Events()
	
	/// Events for UIScrollViewDelegate
	public var onScroll: ScrollViewEvents? = ScrollViewEvents()
	
	/// Set the height of the row.
	public var rowHeight: RowHeight = .`default` {
		didSet {
			switch rowHeight {
			case .fixed(let h):
				self.tableView?.rowHeight = h
				self.tableView?.estimatedRowHeight = h
			case .autoLayout(let estimate):
                self.tableView?.rowHeight = UITableView.automaticDimension
				self.tableView?.estimatedRowHeight = estimate
			case .default:
                self.tableView?.rowHeight = UITableView.automaticDimension
                self.tableView?.estimatedRowHeight = UITableView.automaticDimension
			}
		}
	}
	
	/// Set it `true` to enable cell's prefetch. You must register `prefetch` and `cancelPrefetch`
	/// events inside enabled sections.
	public var prefetchEnabled: Bool {
		set {
			if #available(iOS 10.0, *) {
				switch newValue {
				case true: 	self.tableView!.prefetchDataSource = self
				case false: self.tableView!.prefetchDataSource = nil
				}
			} else {
				debugPrint("Prefetch is available only from iOS 10")
			}
		}
		get {
			if #available(iOS 10.0, *) {
				return (self.tableView!.prefetchDataSource != nil)
			} else {
				debugPrint("Prefetch is available only from iOS 10")
				return false
			}
		}
	}
	
	/// Initialize a new director for given table.
	///
	/// - Parameter table: table manager
	public init(_ table: UITableView) {
		super.init()
		self.tableView = table
		self.rowHeight = .default
		table.delegate = self
		table.dataSource = self
	}
	
	/// Register a new adapter's for table.
	/// Adapter manage a single model type and associate it to a visual representation (a cell).
	///
	/// - Parameter adapter: adapter to register
	public func register(adapter: AbstractAdapterProtocol) {
		let modelID = String(describing: adapter.modelType)
		self.adapters[modelID] = adapter // register adapter
		self.registerCell(forAdapter: adapter)
	}
	
	/// Register multiple adapters for table.
	///
	/// - Parameter adapters: adapters
	public func register(adapters: [AbstractAdapterProtocol]) {
		adapters.forEach { self.register(adapter: $0) }
	}
	
	/// Reload contents of table.
	///
	/// - Parameters:
	///   - task: specify a callback where you can modify the structure of the table (sections & items). At the end of the block automatic
	///			  diffing is performed and a reload is made with using table's animation configuration (`TableReloadAnimations`). If `nil` is
	///			  returned the `TableReloadAnimations.default()` automatic animation is made.
	///   - onEnd: optional callback called at the end of the reload.
	public func reloadData(after task: ((TableDirector) -> (TableReloadAnimationProtocol?))? = nil, onEnd: (() -> (Void))? = nil) {
		guard let t = task else {
			self.tableView?.reloadData()
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { onEnd?() })
			return
		}
		
		
		// Keep a reference to removed items in order to perform diff and animation
		let oldSections: [TableSection] = Array.init(self.sections)
		var oldItemsInSections: [String: [ModelProtocol]] = [:]
		self.sections.forEach { oldItemsInSections[$0.UUID] = Array($0.models) }

		// Execute callback and return animations to perform
		let animationsToPerform = (t(self) ?? TableReloadAnimations.default())

		func executeDiffAndUpdate() {
			// Execute reload for sections
			let changesInSection = SectionChanges.fromTableSections(old: oldSections, new: self.sections)
			changesInSection.applyChanges(toTable: self.tableView, withAnimations: animationsToPerform)
			
			self.sections.enumerated().forEach { (idx,newSection) in
				if let oldSectionItems = oldItemsInSections[newSection.UUID] {
					let diffData = diff(old: oldSectionItems, new: newSection.models)
					let itemChanges = SectionItemsChanges.create(fromChanges: diffData, section: idx)
					itemChanges.applyChangesToSectionItems(ofTable: self.tableView, withAnimations: animationsToPerform)
				}
			}
		}
		
		if #available(iOS 11.0, *) {
			self.tableView?.performBatchUpdates({
				executeDiffAndUpdate()
			}, completion: { end in
				if end { onEnd?() }
			})
		} else {
			self.tableView?.beginUpdates()
			executeDiffAndUpdate()
			self.tableView?.endUpdates()
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { onEnd?() })
		}
	}
	
	/// Change the content of the table.
	///
	/// - Parameter models: array of models to set.
	public func set(sections: [TableSection]) {
		self.sections = sections
	}
	
	/// Append a new section a the end of the table with passed items.
	///
	/// - Parameter models: models to add into the section.
	/// - Returns: created section
	@discardableResult
	public func add(models: [ModelProtocol]) -> TableSection {
		let section = TableSection(models)
		self.sections.append(section)
		return section
	}
	
	/// Insert a new section at given index.
	///
	/// - Parameters:
	///   - section: section to insert.
	///   - index: destination index; if index is invalid or `nil` section is append to the list.
	public func add(section: TableSection, at index: Int? = nil) {
		guard let i = index, i < self.sections.count else {
			self.sections.append(section)
			return
		}
		self.sections.insert(section, at: i)
	}
	
	/// Insert sections starting at given index.
	///
	/// - Parameters:
	///   - sections: sections to insert.
	///   - index: destination starting index; if index is invalid or `nil` sections are append to the list.
	public func add(sections: [TableSection], at index: Int? = nil) {
		guard let i = index, i < self.sections.count else {
			self.sections.append(contentsOf: sections)
			return
		}
		self.sections.insert(contentsOf: sections, at: i)
	}
	
	/// Get section at given index.
	///
	/// - Parameter index: index, if invalid produces `nil` result.
	/// - Returns: section instance if index is valid, `nil` otherwise.
	public func section(at index: Int) -> TableSection? {
		guard index < self.sections.count else { return nil }
		return self.sections[index]
	}
	
	/// Get the first section if exists.
	///
	/// - Returns: first section, `nil` if has no sections.
	public func firstSection() -> TableSection? {
		return self.sections.first
	}
	
	/// Get the last section if exists.
	///
	/// - Returns: last section, `nil` if has no sections.
	public func lastSection() -> TableSection? {
		return self.sections.last
	}
	
	/// Remove all sections from the table.
	///
	/// - Parameter kp: `true` to keep the capacity and optimize operations.
	/// - Returns: count removed sections.
	@discardableResult
	public func removeAll(keepingCapacity kp: Bool = false) -> Int {
		let count = self.sections.count
		self.sections.removeAll(keepingCapacity: kp)
		return count
	}
	
	/// Remove section at given index.
	///
	/// - Parameter index: index of the section to remove
	/// - Returns: removed section, if index is valid, `nil` otherwise.
	@discardableResult
	public func remove(section index: Int) -> TableSection? {
		guard index < self.sections.count else { return nil }
		return self.sections.remove(at: index)
	}
	
	/// Remove sections at given indexes.
	///
	/// - Parameter indexes: indexes of the sections to remove.
	/// - Returns: removed sections in order.
	@discardableResult
	public func remove(sectionsAt indexes: IndexSet) -> [TableSection] {
		var removed: [TableSection] = []
		indexes.reversed().forEach {
			if $0 < self.sections.count {
				removed.append(self.sections.remove(at: $0))
			}
		}
		return removed
	}
	
	/// Swap section at given index to another destination index.
	///
	/// - Parameters:
	///   - sourceIndex: source index
	///   - destIndex: destination index
	public func move(swappingAt sourceIndex: Int, with destIndex: Int) {
		guard sourceIndex < self.sections.count, destIndex < self.sections.count else { return }
		swap(&self.sections[sourceIndex], &self.sections[destIndex])
	}
	
	/// Remove section at given index and insert at destination index.
	///
	/// - Parameters:
	///   - sourceIndex: source index
	///   - destIndex: destination index
	public func move(from sourceIndex: Int, to destIndex: Int) {
		guard sourceIndex < self.sections.count, destIndex < self.sections.count else { return }
		let removed = self.sections.remove(at: sourceIndex)
		self.sections.insert(removed, at: destIndex)
	}
		
	//MARK: Internal Functions
	
	/// Return the context of operation which includes model instance and associated adapter.
	///
	/// - Parameter index: index of target item.
	/// - Returns: model and adapter
	internal func context(forItemAt index: IndexPath) -> (ModelProtocol, TableAdaterProtocolFunctions) {
		let item: ModelProtocol = self.sections[index.section].models[index.row]
		let modelID = String(describing: type(of: item.self))
		guard let adapter = self.adapters[modelID] else {
			fatalError("Failed to found an adapter for model: \(modelID)")
		}
		return (item,adapter as! TableAdaterProtocolFunctions)
	}
	
	/// Return the adapter associated with type of model.
	/// Throw a fatal error if no adapter is created to manage passed model's type.
	///
	/// - Parameter model: model to read.
	/// - Returns: adapter.
	internal func context(forModel model: AnyHashable) -> TableAdaterProtocolFunctions {
		let modelID = String(describing: type(of: model.self))
		guard let adapter = self.adapters[modelID] else {
			fatalError("Failed to found an adapter for \(modelID)")
		}
		return (adapter as! TableAdaterProtocolFunctions)
	}
	
	/// Return the list of adapters used to manage objects at given paths.
	/// Returned list is composed by `PrefetchModelsGroup` objects per each model's type
	/// and includes paths, models instances and associated adapter instance.
	///
	/// - Parameter paths: paths of (optionally eterogeneous) paths to objects.
	/// - Returns: `PrefetchModelsGroup` instance for each involved adapter.
	internal func adapters(forIndexPaths paths: [IndexPath]) -> [PrefetchModelsGroup] {
		var list: [String: PrefetchModelsGroup] = [:]
		paths.forEach { indexPath in
			let model = self.sections[indexPath.section].models[indexPath.item]
			let modelID = String(describing: type(of: model.self))
			
			var context: PrefetchModelsGroup? = list[modelID]
			if context == nil {
				context = PrefetchModelsGroup(adapter: self.adapters[modelID] as! TableAdaterProtocolFunctions)
				list[modelID] = context
			}
			context!.models.append(model)
			context!.indexPaths.append(indexPath)
		}
		
		return Array(list.values)
	}
	
	/// PrefetchModelsGroup groups models instances with given adapters.
	/// Instances of these objects are returned by `adapters(forIndexPaths)` function.
	internal class PrefetchModelsGroup {
		let adapter: 	TableAdaterProtocolFunctions
		var models: 	[ModelProtocol] = []
		var indexPaths: [IndexPath] = []
		
		public init(adapter: TableAdaterProtocolFunctions) {
			self.adapter = adapter
		}
	}
}


// MARK: - TableDirector UITableViewDataSource/UITableViewDelegate
public extension TableDirector {
	
	//MARK: UITableViewDataSource
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return self.sections.count
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.sections[section].models.count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let (model,adapter) = self.context(forItemAt: indexPath)
		let cell = adapter._instanceCell(in: tableView, at: indexPath)
		adapter.dispatch(.dequeue, context: InternalContext(model, indexPath, cell, tableView))
		return cell
	}
	
	// Header & Footer
	
	public func tableView(_ tableView: UITableView, viewForHeaderInSection sectionIdx: Int) -> UIView? {
		guard let header = sections[sectionIdx].headerView else { return nil }
		let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.registerView(header))
		let _ = (header as? AbstractTableHeaderFooterItem)?.dispatch(.dequeue, type: .header, view: view, section: sectionIdx, table: tableView)
		return view
	}
	
	public func tableView(_ tableView: UITableView, viewForFooterInSection sectionIdx: Int) -> UIView? {
		guard let footer = sections[sectionIdx].footerView else { return nil }
		let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.registerView(footer))
		let _ = (footer as? AbstractTableHeaderFooterItem)?.dispatch(.dequeue, type: .footer, view: view, section: sectionIdx, table: tableView)
		return view
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section].headerTitle
	}
	
	public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return self.sections[section].footerTitle
	}
	
	public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		let item = (self.sections[section].headerView as? AbstractTableHeaderFooterItem)
		guard let height = item?.dispatch(.height, type: .header, view: nil, section: section, table: tableView) as? CGFloat else {
            return (self.headerHeight ?? UITableView.automaticDimension)
		}
		return height
	}
	
	public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		let item = (self.sections[section].footerView as? AbstractTableHeaderFooterItem)
		guard let height = item?.dispatch(.height, type: .footer, view: nil, section: section, table: tableView) as? CGFloat else {
            return (self.footerHeight ?? UITableView.automaticDimension)
		}
		return height
	}
	
	public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
		let item = (self.sections[section].headerView as? AbstractTableHeaderFooterItem)
		guard let estHeight = item?.dispatch(.estimatedHeight, type: .header, view: nil, section: section, table: tableView) as? CGFloat else {
			guard let height = item?.dispatch(.height, type: .header, view: nil, section: section, table: tableView) as? CGFloat else {
                return (self.headerHeight ?? UITableView.automaticDimension)
			}
			return height
		}
		return estHeight
	}
	
	public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
		let item = (self.sections[section].footerView as? AbstractTableHeaderFooterItem)
		guard let height = item?.dispatch(.estimatedHeight,type: .footer, view: nil, section: section, table: tableView) as? CGFloat else {
			guard let height = item?.dispatch(.height, type: .footer, view: nil, section: section, table: tableView) as? CGFloat else {
                return (self.footerHeight ?? UITableView.automaticDimension)
			}
			return height
		}
		return height
	}
	
	public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let item = (self.sections[section].headerView as? AbstractTableHeaderFooterItem)
		let _ = item?.dispatch(.willDisplay, type: .header, view: view, section: section, table: tableView)
		self.on.willDisplayHeader?( (view,section,tableView) )
	}
	
	public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
		let item = (self.sections[section].footerView as? AbstractTableHeaderFooterItem)
		let _ = item?.dispatch(.willDisplay, type: .footer, view: view, section: section, table: tableView)
		self.on.willDisplayFooter?( (view,section,tableView) )
	}
	
	public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
		guard section < self.sections.count else { return }
		let item = (self.sections[section].headerView as? AbstractTableHeaderFooterItem)
		let _ = item?.dispatch(.endDisplay, type: .header, view: view, section: section, table: tableView)
		self.on.endDisplayHeader?( (view,section,tableView) )
	}
	
	public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
		guard section < self.sections.count else { return }
		let item = (self.sections[section].footerView as? AbstractTableHeaderFooterItem)
		let _ = item?.dispatch(.endDisplay, type: .footer, view: view, section: section, table: tableView)
		self.on.endDisplayFooter?( (view,section,tableView) )
	}
	
	// Inserting or Deleting Table Rows
	
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.commitEdit, context: InternalContext(model, indexPath, nil, tableView, param1: editingStyle))
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.canEdit, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? false)
	}
	
	// Reordering Table Rows

	public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.canMoveRow, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? false)
	}

	public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: sourceIndexPath)
		adapter.dispatch(.moveRow, context: InternalContext(model, sourceIndexPath, nil, tableView, param1: destinationIndexPath))
	}
	
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if case .fixed(let h) = self.rowHeight {
			return h
		}
		
		switch self.rowHeight {
		case .default:
			let (model,adapter) = self.context(forItemAt: indexPath)
            return (adapter.dispatch(.rowHeight, context: InternalContext(model, indexPath, nil, tableView)) as? CGFloat) ?? UITableView.automaticDimension
		case .autoLayout(_):
            return UITableView.automaticDimension
		default:
			return self.tableView!.rowHeight
		}
	}
	
	public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		let (model,adapter) = self.context(forItemAt: indexPath)
        return ((adapter.dispatch(.rowHeightEstimated, context: InternalContext(model, indexPath, nil, tableView)) as? CGFloat) ?? UITableView.automaticDimension)
	}
	
	public func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.indentLevel, context: InternalContext(model,indexPath, nil, tableView)) as? Int) ?? 1)
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.willDisplay, context: InternalContext.init(model, indexPath, cell, tableView))
	}
	
	@available(iOS 11.0, *)
	public func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldSpringLoad, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? true)
	}
	
	public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return adapter.dispatch(.editActions, context: InternalContext(model, indexPath, nil, tableView)) as? [UITableViewRowAction]
	}
	
	public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.tapOnAccessory, context: InternalContext(model, indexPath, nil, tableView))
	}
	
	public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.willSelect, context: InternalContext(model, indexPath, nil, tableView)) as? IndexPath) ?? indexPath)
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		
		let action = ((adapter.dispatch(.tap, context: InternalContext(model,indexPath,nil,tableView)) as? TableSelectionState) ?? .none)
		switch action {
		case .deselect:			tableView.deselectRow(at: indexPath, animated: false)
		case .deselectAnimated:	tableView.deselectRow(at: indexPath, animated: true)
		default:				break
		}
	}

	public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return (adapter.dispatch(.willDeselect, context: InternalContext(model, indexPath, nil, tableView)) as? IndexPath)
	}
	
	public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didDeselect, context: InternalContext(model, indexPath, nil, tableView))
	}
	
	public func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.willBeginEdit, context: InternalContext(model, indexPath, nil, tableView))
	}
	
	public func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
		guard let index = indexPath else { return }
		let (model,adapter) = self.context(forItemAt: index)
		adapter.dispatch(.didEndEdit, context: InternalContext(model, indexPath!, nil, tableView))
	}
	
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		let (model,adapter) = self.context(forItemAt: indexPath)
        return ((adapter.dispatch(.editStyle, context: InternalContext(model, indexPath, nil, tableView)) as? UITableViewCell.EditingStyle) ?? .none)
	}
	
	public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return (adapter.dispatch(.deleteConfirmTitle, context: InternalContext(model, indexPath, nil, tableView)) as? String)
	}
	
	public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.editShouldIndent, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? true)
	}
	
	public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		let (model,adapter) = self.context(forItemAt: sourceIndexPath)
		return ((adapter.dispatch(.moveAdjustDestination, context: InternalContext.init(model, sourceIndexPath, nil, tableView, param1: proposedDestinationIndexPath)) as? IndexPath) ?? proposedDestinationIndexPath)
	}
	
	public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		self.adapters.forEach {
			($0.value as! TableAdaterProtocolFunctions).dispatch(.endDisplay, context: InternalContext(nil, indexPath, cell, tableView))
		}
	}
	
	public func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldShowMenu, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? false)
	}
	
	public func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.canPerformMenuAction, context: InternalContext(model, indexPath, nil, tableView, param1: action, param2: sender)) as? Bool) ?? true)
	}
	
	public func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.performMenuAction, context: InternalContext(model, indexPath, nil, tableView, param1: action, param2: sender))
	}
	
	public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.shouldHighlight, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? true)
	}
	
	public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didHighlight, context: InternalContext(model, indexPath, nil, tableView))
	}
	
	public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
		let (model,adapter) = self.context(forItemAt: indexPath)
		adapter.dispatch(.didUnhighlight, context: InternalContext(model, indexPath, nil, tableView))
	}
	
	public func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return ((adapter.dispatch(.canFocus, context: InternalContext(model, indexPath, nil, tableView)) as? Bool) ?? true)
	}
	
	@available(iOS 11, *)
	public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return adapter.dispatch(.leadingSwipeActions, context: InternalContext.init(model, indexPath, nil, tableView)) as? UISwipeActionsConfiguration
	}
	
	@available(iOS 11.0, *)
	public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let (model,adapter) = self.context(forItemAt: indexPath)
		return adapter.dispatch(.trailingSwipeActions, context: InternalContext.init(model, indexPath, nil, tableView)) as? UISwipeActionsConfiguration
	}
	
	/// Indexes
	
	public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		return self.tableIndexes()
	}
	
	public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
		let indexes = (self.tableIndexes() ?? [])
		guard indexes.count != self.sections.count else { return index } // same items
		
		guard let callback = self.on.sectionForSectionIndex else {
			fatalError("You must implement TableDirector's `sectionForSectionIndex` event if you use `indexTitle` from sections.")
		}
		return callback(title,index)
	}
		
	private func tableIndexes() -> [String]? {
		let indexes = self.sections.compactMap({ $0.indexTitle })
		guard indexes.count > 0 else { return nil }
		return indexes
	}
	
	/// Prefetch Support
	
	public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
		self.adapters(forIndexPaths: indexPaths).forEach {
			$0.adapter.dispatch(.prefetch, context: InternalContext($0.models, $0.indexPaths, tableView))
		}
	}
	
	public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
		self.adapters(forIndexPaths: indexPaths).forEach {
			$0.adapter.dispatch(.cancelPrefetch, context: InternalContext($0.models, $0.indexPaths, tableView))
		}
	}
	
}

// MARK: - UIScrollViewDelegate Events

public extension TableDirector {
	
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


// MARK: - TableDirector Cell/ReusableView Registration Support

public extension TableDirector {
	
	/// Register a new cell for given adapter.
	///
	/// - Parameter adapter: adapter
	/// - Returns: `true` if cell is registered, `false` otherwise. If cell is already registered it returns `false`.
	@discardableResult
	internal func registerCell(forAdapter adapter: AbstractAdapterProtocol) -> Bool {
		let identifier = adapter.cellReuseIdentifier
		guard !cellIDs.contains(identifier) else {
			return false
		}
		let bundle = Bundle.init(for: adapter.cellClass)
		if let _ = bundle.path(forResource: identifier, ofType: "nib") {
			let nib = UINib(nibName: identifier, bundle: bundle)
			self.tableView?.register(nib, forCellReuseIdentifier: identifier)
		} else if adapter.registerAsClass {
			self.tableView?.register(adapter.cellClass, forCellReuseIdentifier: identifier)
		}
		cellIDs.insert(identifier)
		return true
	}
	
	/// Register a new reusable view for header/footer.
	///
	/// - Parameter view: abstract view to register.
	/// - Returns: `true` if view is registered, `false` otherwise. If view is already registered it returns `false`.
	internal func registerView(_ view: TableHeaderFooterProtocol) -> String {
		let identifier = view.reuseIdentifier
		guard !self.headersFootersIDs.contains(identifier) else { return identifier}
		
		let bundle = Bundle(for: view.viewClass)
		if let _ = bundle.path(forResource: identifier, ofType: "nib") {
			let nib = UINib(nibName: identifier, bundle: bundle)
			self.tableView?.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
		} else if view.registerAsClass {
			self.tableView?.register(view.viewClass, forCellReuseIdentifier: identifier)
		}
		return identifier
	}
	
	
}

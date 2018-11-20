import UIKit

public class FlowStackView: UIScrollView {
	
	//MARK: Additional Structures
	
	/// Visibility of the separator between rows.
	///
	/// - all: all separators must be visibile unless explicitly set per row.
	/// - none: no separators must be visibile unless explicitly set per row.
	/// - hideLast: hide the last visible separator unless explicitly set per row.
	public enum SeparatorVisibility {
		case all
		case none
		case hideLast
	}
	
	/// Define the scroll position for `scrollToRow()` function.
	///
	/// - none: make the row enterly visible (if possible) by moving to it with less scroll offset possible.
	/// - top: make the row visible by placing its top side at the same position of the stackview's top (if possible).
	/// - middle: make the row visible by placing the cell centered vertically in stack view (if possible).
	/// - bottom: make the visible by placing its bottom side at the bottom side of the stackview (if possible).
	public enum ScrollPosition {
		case none
		case top
		case middle
		case bottom
	}
	
	/// Define the row position of the scroll.
	///
	/// - index: scroll at the specified index.
	/// - top: at the top.
	/// - bottom: at the bottom.
	public enum RowPosition {
		case index(_: Int)
		case top
		case bottom
	}
	
	/// Define the style of the row applied as default style for new
	/// row added to the stack view.
	public struct RowStyle {

		//MARK: - Separator Style

		/// Color of the separator. By default is the same color used for UITableView's separators.
		var separatorColor: UIColor = UIColor.red

		/// Thickness of the separator. By default is 1 pixel height.
		var separatorThickness: CGFloat = 2.0

		/// The default inset of the separator (only for left/right constraints). By default is `.zero`.
		var separatorInset: UIEdgeInsets = .zero

		/// How manage the visibility of the separators.
		var separatorVisibility: SeparatorVisibility = .all

		//MARK: - Row Style

		/// Inset of the row, by default is `.zero`
		var rowInset: UIEdgeInsets = .zero

		/// Background color applied to the separator
		var rowBackground: UIColor = UIColor.yellow

		var highlightedRowBackground: UIColor = UIColor.orange
	}

	//MARK: Private Properties

	/// Direction of the scrolling
	private let scrollingDirection: NSLayoutConstraint.Axis
	
	//MARK: Properties

	/// Handler to call on pull to refresh.
	private var onPullToRefresh: (() -> Void)?

	/// Implement pull to refresh handler
	@available(iOS 10.0, *)
	public func addPullToRefresh(_ handler: (() -> Void)?) {
		if self.refreshControl == nil {
			self.refreshControl = UIRefreshControl(frame: .zero)
		}
		self.onPullToRefresh = handler
	}

	/// Refresh control
	@available(iOS 10.0, *)
	public override var refreshControl: UIRefreshControl? {
		didSet {
			super.refreshControl = refreshControl
			refreshControl?.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
		}
	}

	/// The style used to manage a new row added to the stack.
	public var rowStyle = RowStyle()

	/// Returns an array containing all the rows in
	/// the stack view in the same order they appear visually.
	public var rows: [FlowStackViewRow] {
		return self.stackView.arrangedSubviews.compactMap({
			$0 as? FlowStackViewRow
		})
	}
	
	/// Return an array containing all the view's used into the rows
	/// of the stack view in the same order they appear visually.
	public var views: [UIView] {
		return self.stackView.arrangedSubviews.compactMap({
			($0 as? FlowStackViewRow)?.contentView
		})
	}
	
	/// Internal stackview instance
	public lazy var stackView: UIStackView = {
		let stackView = UIStackView()
		stackView.axis = scrollingDirection
		stackView.translatesAutoresizingMaskIntoConstraints = false
		return stackView
	}()

	/// Return the number of rows in stack view.
	public var count: Int {
		return stackView.arrangedSubviews.count
	}
	
	/// Return the row at specified index.
	///
	/// - Parameter index: index to get.
	/// - Returns: return `nil` if index if out of bounds.
	public func rowAt(_ index: Int) -> FlowStackViewRow? {
		guard index >= 0, index < stackView.arrangedSubviews.count else {
			return nil
		}
		return self.stackView.arrangedSubviews[index] as? FlowStackViewRow
	}
	
	//MARK: Initialize
	
	/// Initialize a new stack view by specifing the direction of the scrolling.
	///
	/// - Parameter direction: direction of the scrolling, by default is `.vertical`.
	public init(direction: NSLayoutConstraint.Axis = .vertical) {
		self.scrollingDirection = direction
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(stackView)

		if #available(iOS 11, *) {
			NSLayoutConstraint.activate([
				stackView.topAnchor.constraint(equalTo: (direction == .vertical ? topAnchor : safeAreaLayoutGuide.topAnchor)),
				stackView.bottomAnchor.constraint(equalTo: (direction == .vertical ? bottomAnchor : safeAreaLayoutGuide.bottomAnchor)),
				stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
				stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
				])
		} else {
			NSLayoutConstraint.activate([
				stackView.topAnchor.constraint(equalTo: topAnchor),
				stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
				stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
				stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			])
		}

		stackView.widthAnchor.constraint(equalTo: widthAnchor).isActive = (scrollingDirection == .vertical)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	//MARK: - Add Rows
	
	/// Add specified views inside the stack view by creating a custom row for each one.
	///
	/// - Parameters:
	///   - rowViews: views to place.
	///   - index: position to place each view, by default is `.bottom`.
	///   - animated: `true` to add views with animation. By default is `false`.
	public func addRows(_ rowViews: [UIView], at index: RowPosition = .bottom, animated: Bool = false) {
		rowViews.forEach {
			self.addRowWithView($0, at: index, animated: animated)
		}
	}
	
	/// Add a new view inside the stack view.
	///
	/// - Parameters:
	///   - rowView: view to place.
	///   - index: position of the view, by default is `.bottom`.
	///   - animated: `true` to add views with animation. By default is `false`.
	/// - Returns: row which contains the view.
	@discardableResult
	public func addRowWithView(_ rowView: UIView, at index: RowPosition = .bottom, animated: Bool = false) -> FlowStackViewRow {
		self.removeRow(self.rowForView(rowView)?.row, animated: animated)
		
		let row = FlowStackViewRow(rowView, style: self.rowStyle, direction: scrollingDirection)
		row.stackView = self
		self.stackView.insertArrangedSubview(row, at: index)
		self.updateSeparatorVisibilityForRow(row)
		
		let rowBefore = self.rowBefore(row)
		self.updateSeparatorVisibilityForRow(rowBefore)
		
		if animated {
			row.alpha = 0
			layoutIfNeeded()
			UIView.animate(withDuration: 0.3) {
				row.alpha = 1
			}
		}
		
		return row
	}
	
	//MARK: - Remove Rows

	/// Remove view and associated row from stack view.
	///
	/// - Parameters:
	///   - rowView: view to remove.
	///   - animated: `true` to make the transition animated, `false` by default.
	/// - Returns: removed row with view.
	@discardableResult
	public func removeRowForView(_ rowView: UIView, animated: Bool = false) -> FlowStackViewRow? {
		guard let row = rowView.superview as? FlowStackViewRow else {
			return nil
		}
		self.removeRow(row)
		return row
	}
	
	/// Remove row at specified index.
	///
	/// - Parameters:
	///   - index: index of the row to remove.
	///   - animated: `true` to make the transition animated, `false` by default.
	/// - Returns: removed row, `nil` if index is invalid.
	public func removeRowAt(_ index: Int, animated: Bool = false) -> FlowStackViewRow? {
		guard index >= 0, index < self.stackView.arrangedSubviews.count,
			let rowToRemove = stackView.arrangedSubviews[index] as? FlowStackViewRow else {
			return nil
		}
		self.removeRow(rowToRemove, animated: animated)
		return rowToRemove
	}
	
	/// Remove all rows from the stack view.
	///
	/// - Parameter animated: `true` to make transition animated, `false` by default.
	public func removeAllRows(animated: Bool = false) {
		stackView.arrangedSubviews.forEach {
			self.removeRow($0 as? FlowStackViewRow, animated: animated)
		}
	}

	//MARK: - Hide/Unhide Rows
	
	/// Make the row associated with passed view visible/invisible.
	///
	/// - Parameters:
	///   - visible: `true` to make the row visible, `false` to hide it.
	///   - view: view to hide.
	///   - animated: `true` to make transition animated, `false` by default.
	public func setRowVisible(_ visible: Bool, forView view: UIView, animated: Bool = false) {
		guard let row = view.superview as? FlowStackViewRow, row.superview == self.stackView else {
			debugPrint("View \(view) is not part of the stack view \(self)")
			return
		}
		UIView.execute(animated: animated, animations: {
			row.isHidden = !visible
			row.layoutIfNeeded()
		}) {
			row.isHidden = !visible
		}
	}
	
	/// Make the rows associated with passed views visible/invisible.
	///
	/// - Parameters:
	///   - visible: `true` to make rows visible, `false` to hide it.
	///   - views: views to hide.
	///   - animated: `true` to make transition animated, `false` by default.
	public func setRowsVisible(_ visible: Bool, forViews views: [UIView], animated: Bool = false) {
		views.forEach {
			self.setRowVisible(visible,
							   forView: $0,
							   animated: animated)
		}
	}
	
	/// Make the rows at given indexes visible/invisible.
	///
	/// - Parameters:
	///   - visible: `true` to make rows visible, `false` to hide it.
	///   - indexes: indexes of the affected rows.
	///   - animated: `true` to make transition animated, `false` by default.
	public func setRowsVisible(_ visible: Bool, atIndexes indexes: IndexSet, animated: Bool = false) {
		indexes.reversed().enumerated().forEach {
			self.setRowVisible(visible,
							   forView: self.stackView.arrangedSubviews[$0.element],
							   animated: animated)
		}
	}
	
	/// Return `true` if row for specified view is visible.
	///
	/// - Parameter view: view to check. Must be part of the stackview.
	/// - Returns: `true` if view is visibile, `false` otherwise (even if view is not part of the stack view).
	public func isRowForViewVisible(_ view: UIView) -> Bool {
		guard let row = view.superview as? FlowStackViewRow, row.superview == self.stackView else {
			return false
		}
		return row.isHidden
	}
	
	//MARK: - Get Rows
	
	/// Return the row which contains a specified view.
	///
	/// - Parameter view: view to search.
	/// - Returns: row parent of the view, `nil` if view is not part of the stack view.
	public func rowForView(_ view: UIView) -> (index: Int, row: FlowStackViewRow)? {
		guard let row = view.superview as? FlowStackViewRow,
			  let idx = self.stackView.arrangedSubviews.firstIndex(of: row) else {
			return nil
		}
		return (idx, self.stackView.arrangedSubviews[idx] as! FlowStackViewRow)
	}
	
	/// Return the index of the row associated with specified view.
	///
	/// - Parameter view: view to search.
	/// - Returns: `nil` if view is not part of the stack view, otherwise the index of the view in stack view.
	public func indexOfRowForView(_ view: UIView) -> Int? {
		guard let row = view.superview as? FlowStackViewRow, row.superview == self.stackView else { return nil }
		return self.indexOfRow(row)
	}
	
	/// Return the index of the row.
	///
	/// - Parameter row: row of the index.
	/// - Returns: index of the row, `nil` if row is not part of the stack view.
	public func indexOfRow(_ row: FlowStackViewRow) -> Int? {
		return self.stackView.arrangedSubviews.firstIndex(of: row)
	}
	
	//MARK: - Scroll To Row
	
	/// Scroll to row associated with specified view.
	///
	/// - Parameters:
	///   - view: view to make visible.
	///   - position: final position of the scrolled row in stack view, `.none` by default.
	///   - animated: `true` to make transition animated, `false` otherwise.
	public func scrollToRowForView(_ view: UIView, position: ScrollPosition = .none, animated: Bool = false) {
		guard let row = view.superview as? FlowStackViewRow, row.superview == self.stackView else { return }
		self.scrollToRow(row, position: position, animated: animated)
	}
	
	/// Scroll to row at specified index.
	///
	/// - Parameters:
	///   - index: index of the row, if invalid no operation will be made.
	///   - position: final position of the scrolled row in stack view, `.none` by default.
	///   - animated: `true` to make transition animated, `false` otherwise.
	public func scrollToRowAt(_ index: Int, position: ScrollPosition = .none, animated: Bool = false) {
		guard index >= 0, index < self.stackView.arrangedSubviews.count,
			let row = self.stackView.arrangedSubviews[index] as? FlowStackViewRow else { return }
		self.scrollToRow(row, position: position, animated: animated)
	}
	
	/// Scroll to specified row inside the stack view.
	///
	/// - Parameters:
	///   - row: row to make visible.
	///   - position: final position of the scrolled row in stack view, `.none` by default.
	///   - animated: `true` to make transition animated, `false` otherwise.
	public func scrollToRow(_ row: FlowStackViewRow, position: ScrollPosition = .none, animated: Bool = false) {
		let rowRect = self.convert(row.frame, from: self.superview)
		guard position != .none else {
			self.scrollRectToVisible(rowRect, animated: animated)
			return
		}
		
		var yOffset: CGFloat?
		switch position {
		case .top:		yOffset = rowRect.minY
		case .middle:	yOffset = rowRect.minY - ((self.bounds.height - rowRect.height) / 2.0)
		case .bottom:	yOffset = rowRect.minY - (self.bounds.height - rowRect.height)
		default:		break
		}
		if var yOffset = yOffset {
			// adjust the scroll offset if it exceed the limit of content size
			let overflowOffset = (yOffset + self.bounds.height) - self.contentSize.height
			if overflowOffset > 0 {
				yOffset -= overflowOffset
			}
			if yOffset < 0 {
				yOffset = 0
			}
			self.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animated)
		}
	}

	//MARK: Pull To Refresh

	/// End pull to refresh if any.
	@available(iOS 10.0, *)
	public func endPullRefresh() {
		DispatchQueue.main.async {
			self.refreshControl?.endRefreshing()
		}
	}

	/// Method calaled by UIRefreshControl class when begin activity.
	///
	/// - Parameter sender: sender
	@available(iOS 10.0, *)
	@objc func didPullToRefresh(_ sender: Any?) {
		onPullToRefresh?()
	}
	
	//MARK: Private Functions

	private func removeRow(_ row: FlowStackViewRow?, animated: Bool = false) {
		let rowBefore = self.rowBefore(row)
		UIView.execute(animated: animated, animations: {
			row?.isHidden = true
		}, complete: { [weak self] in
			row?.removeFromSuperview()
			row?.stackView = nil
			self?.updateSeparatorVisibilityForRow(rowBefore)
		})
	}

	private func rowBefore(_ row: FlowStackViewRow?) -> FlowStackViewRow? {
		guard let row = row else { return nil }
		guard let index = self.stackView.arrangedSubviews.index(of: row), index > 0 else { return nil }
		return stackView.arrangedSubviews[index - 1] as? FlowStackViewRow
	}
	
	internal func updateSeparatorVisibilityForRow(_ row: FlowStackViewRow?) {
		guard let row = row else { return }
		if let forcedVisibility = row.separatorForcedVisibility {
			row.isSeparatorHidden = !forcedVisibility
			return
		}
		switch self.rowStyle.separatorVisibility {
		case .hideLast:	row.isSeparatorHidden = (row === self.stackView.arrangedSubviews.last)
		case .all:		row.isSeparatorHidden = false
		case .none:		row.isSeparatorHidden = true
		}
	}
	
}

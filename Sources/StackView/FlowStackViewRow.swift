import UIKit

public class FlowStackViewRow: UIView {

	//MARK: Private Properties

	/// Associated stack view
	internal weak var stackView: FlowStackView? = nil

	/// Internal visibility state for separator.
	/// If `nil` no forced behaviour is set.
	internal var separatorForcedVisibility: Bool?

	//MARK: Public Properties

	/// Associated parent stack view.
	public var parentStackView: FlowStackView? {
		return stackView
	}

	/// Content view
	public let contentView: UIView
	
	/// Separator view
	public let separatorView: FlowStackViewSeparator
	
	/// Return `true` if separator is visible, `false` otherwise.
	public var isSeparatorHidden: Bool {
		get {
			return self.separatorView.isHidden
		}
		set {
			self.separatorView.isHidden = newValue
		}
	}

	/// The background color of the row when highlighted (if available).
	/// Initially the value is inherited from parent stack view's `rowStyle`.
	public var rowHighlightColor = UIColor.highlightGray
	
	/// The background color of the row.
	/// Initially the value is inherited from parent stack view's `rowStyle`.
	public var rowBackgroundColor = UIColor.clear {
		didSet {
			self.backgroundColor = rowBackgroundColor
		}
	}
	
	/// The insets applied to the row.
	/// Initially the value is inherited from parent stack view's `rowStyle`.
	public var rowInset: UIEdgeInsets {
		get {
			return self.layoutMargins
		}
		set {
			self.layoutMargins = newValue
		}
	}

	//MARK: Initialize

	/// Initialize a new row with specified content view.
	///
	/// - Parameters:
	///   - contentView: content view of the row.
	///   - style: style applied to the row.
	///   - direction: direction of the separator.
	public init(_ contentView: UIView, style: FlowStackView.RowStyle, direction: NSLayoutConstraint.Axis) {
		self.contentView = contentView
		self.separatorView = FlowStackViewSeparator(style: style, direction: direction)

		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false
		if #available(iOS 11, *) {
			self.insetsLayoutMarginsFromSafeArea = false
		}
		self.clipsToBounds = true
		self.contentView.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(self.contentView)
		
		let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		bottomConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)
		
		NSLayoutConstraint.activate([
			contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			bottomConstraint
		])
		
		({
			self.rowBackgroundColor = style.rowBackground
			self.rowHighlightColor = style.highlightedRowBackground
			self.rowInset = style.rowInset
			
			self.separatorView.addToRow(self, direction: direction)
		})()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	//MARK: Public Functions

	/// Force visibility of the separator.
	///
	/// - Parameter visible: `true` to force visibility, `false` to force hidden or `nil` to inherit the behaviour of the parent stack
	public func setSeparatorVisible(_ visible: Bool?) {
		self.separatorForcedVisibility = visible
		self.stackView?.updateSeparatorVisibilityForRow(self)
	}

}

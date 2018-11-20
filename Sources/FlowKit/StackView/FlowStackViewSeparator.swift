import UIKit

public class FlowStackViewSeparator: UIView {

	//MARK: Private Properties

	/// Minimum side constraint for separator view
	/// (leading in horizontal, top in vertical stack view direction)
	private weak var minConstraint: NSLayoutConstraint?

	/// Maximum side constraint for separator view
	/// (trailing in horizontal, bottom in vertical stack view direction)
	private weak var maxConstraint: NSLayoutConstraint?

	/// Type of separator (vertical or horizontal)
	private var separatorDirection: NSLayoutConstraint.Axis

	///MARK: Public Properties

	/// Color of the separator
	public var color: UIColor {
		get {
			return self.backgroundColor ?? .clear
		}
		set {
			self.backgroundColor = newValue
		}
	}
	
	/// Thickness of the separator
	public var thickness: CGFloat = 1.0 {
		didSet {
			self.invalidateIntrinsicContentSize()
		}
	}
	
	public var insets: UIEdgeInsets = .zero {
		didSet {
			self.minConstraint?.constant = insets.left
			self.maxConstraint?.constant = -insets.right
		}
	}

	//MARK: Init
	
	public init(style: FlowStackView.RowStyle, direction: NSLayoutConstraint.Axis) {
		self.separatorDirection = direction
		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false
		
		self.color = style.separatorColor
		self.thickness = style.separatorThickness
		self.insets = style.separatorInset
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	//MARK: - Private Function

	public override var intrinsicContentSize: CGSize {
		switch separatorDirection {
		case .horizontal:
			return CGSize(width: thickness, height: UIView.noIntrinsicMetric)
		case .vertical:
			return CGSize(width: UIView.noIntrinsicMetric, height: thickness)
		}
	}

	internal func addToRow(_ row: FlowStackViewRow, direction: NSLayoutConstraint.Axis) {
		self.removeFromSuperview()
		row.addSubview(self)

		switch direction {
		case .horizontal:
			self.minConstraint = self.topAnchor.constraint(equalTo: row.topAnchor)
			self.maxConstraint = self.bottomAnchor.constraint(equalTo: row.bottomAnchor)

			NSLayoutConstraint.activate([
				self.minConstraint!,
				self.maxConstraint!,
				trailingAnchor.constraint(equalTo: row.trailingAnchor)
			])

		case .vertical:
			self.minConstraint = self.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: self.insets.left)
			self.maxConstraint = self.trailingAnchor.constraint(equalTo: row.trailingAnchor,  constant: -self.insets.right)

			NSLayoutConstraint.activate([
				self.bottomAnchor.constraint(equalTo: row.bottomAnchor),
				self.minConstraint!,
				self.maxConstraint!
			])
		}
	}
	
}

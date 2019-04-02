import UIKit

public extension UIView {
	
	func extendToSuperview() {
		guard let superview = self.superview else { return }
		NSLayoutConstraint.activate([
			leadingAnchor.constraint(equalTo: superview.leadingAnchor),
			trailingAnchor.constraint(equalTo: superview.trailingAnchor),
			bottomAnchor.constraint(equalTo: superview.bottomAnchor),
			topAnchor.constraint(equalTo: superview.topAnchor)
		])
	}
	
	static func execute(animated: Bool, animations: (() -> Void)?, complete: (() -> Void)?) {
		switch animated {
		case true:
			UIView.animate(withDuration: 0.25, animations: { animations?() }) { finished in
				guard finished else { return }
				complete?()
			}
		case false:
			animations?()
			complete?()
		}
	}
	
}

public extension NSLayoutAnchor {
	
	@objc func constraint(equalTo anchor: NSLayoutAnchor<AnchorType>, priority: UILayoutPriority) -> NSLayoutConstraint {
		let newConstraint = self.constraint(equalTo: anchor)
		newConstraint.priority = priority
		return newConstraint
	}

}

public extension UILayoutPriority {
	
	static let requiredLower = UILayoutPriority(UILayoutPriority.required.rawValue - 1)
	
}

public extension UIColor {
	
	static var highlightGray = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1)
	
}

public extension UIStackView {
	
	func insertArrangedSubview(_ view: UIView, at index: FlowStackView.RowPosition) {
		switch index {
		case .index(let idx):
			self.insertArrangedSubview(view, at: idx)
		case .top:
			self.insertArrangedSubview(view, at: 0)
		case .bottom:
			self.addArrangedSubview(view)
		}
	}

}

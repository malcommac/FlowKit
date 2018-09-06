//
//  TableHeaderView.swift
//  ExampleApp
//
//  Created by Daniele Margutti on 21/04/2018.
//  Copyright © 2018 FlowKit. All rights reserved.
//

import Foundation
import UIKit

public class TableExampleHeaderView: UITableViewHeaderFooterView {
	
	@IBOutlet public var titleLabel: UILabel?
	
	public var whenTapped: (() -> Void)?
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
		self.addGestureRecognizer(tapGesture)
	}
	
	@objc private func tapped() {
		whenTapped?()
	}
}

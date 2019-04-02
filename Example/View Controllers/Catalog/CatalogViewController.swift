//
//  CatalogViewController.swift
//  Example
//
//  Created by dan on 12/02/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

class CatalogViewController: UIViewController {

	@IBOutlet public var tableView: UITableView!

	private var tableDirector: TableDirector?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "FlowKit"

		prepareTable()
		prepareTableContents()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Test", style: .plain, target: self, action: #selector(didTap))
	}

    @objc public func didTap(_ sender: Any) {
        tableDirector?.reload(afterUpdate: { d in
            d.remove(section: 0)
            return .automatic
        }, completion: nil)
    }
    
	// MARK: - Table Configuration -

	private func prepareTable() {
		tableDirector = TableDirector(table: tableView)
		tableDirector?.rowHeight = .explicit(60)

		let catalogAdapter = TableCellAdapter<CatalogItem, CatalogItemCell>()
		tableDirector?.registerCellAdapter(catalogAdapter)

		catalogAdapter.events.dequeue = { ctx in
			ctx.cell?.item = ctx.element
		}

		catalogAdapter.events.didSelect = { ctx in
			self.selectCatalogItem(ctx.element)
			return .deselectAnimated
		}
	}

	// MARK: - Prepare Contents -

	private func prepareTableContents() {
		let tables_ex1 = CatalogItem(id: "ex1", icon: "tableView".image, title: "Team Players Example")
		let sectionTables = TableSection(elements: [tables_ex1], header: "UITableView Examples")

		tableDirector?.add(sections: [sectionTables])
		tableDirector?.reload()
	}

	// MARK: - Helpers -

	private func selectCatalogItem(_ item: CatalogItem?) {
		guard let vc = controllerForCatalogItem(item) else {
			return
		}
		navigationController?.pushViewController(vc, animated: true)
	}

	private func controllerForCatalogItem(_ item: CatalogItem?) -> UIViewController? {
		guard let item = item else { return nil }
		switch item.id {
		case "ex1":
			return TeamPlayersController.create()
		default:
			return nil
		}
	}
	
}

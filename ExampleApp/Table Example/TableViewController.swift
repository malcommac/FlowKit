//
//  FirstViewController.swift
//  ExampleApp
//
//  Created by Daniele Margutti on 21/04/2018.
//  Copyright © 2018 FlowKit. All rights reserved.
//

import UIKit
import FlowKit

class TableViewController: UIViewController {
	
	@IBOutlet public var tableView: UITableView?

	override func viewDidLoad() {
		super.viewDidLoad()

		let articleAdpt = TableAdapter<Article,TableArticleCell>()
		articleAdpt.on.dequeue = { ctx in
			ctx.cell?.titleLabel?.text = ctx.model.title
			ctx.cell?.subtitleLabel?.text = ctx.model.text
		}
		articleAdpt.on.tap = { ctx in
			print("Tapped on article \(ctx.model.identifier)")
			return .deselectAnimated
		}
		self.tableView?.director.register(adapter: articleAdpt)
		
		
		
		self.tableView?.director.add(section: self.getWinnerSection())

		self.tableView?.director.rowHeight = .autoLayout(estimated: 200)
		self.tableView?.director.reloadData(after: { _ in
			
			return TableReloadAnimations.default()
		}, onEnd: nil)
		
	}
	
	func getWinnerSection() -> TableSection {
		let articles = (0..<7).map {
			return Article(title: "Article_Title_\($0)".loc, text: "Article_Text_\($0)".loc)
		}
		
		let header = TableSectionView<TableExampleHeaderView>()
		header.on.height = { ctx in
			return max(ctx.tableSize!.width, ctx.tableSize!.height) / 15
		}
        header.on.dequeue = { ctx in
            ctx.view?.titleLabel?.text = "Cogito Ergo Sum"
        }

		
		let footer = TableSectionView<TableFooterExample>()
        footer.on.height = { ctx in
            return max(ctx.tableSize!.width, ctx.tableSize!.height) / 20
        }
		footer.on.dequeue = { ctx in
			ctx.view?.titleLabel?.text = "\(articles.count) Articles"
		}
		
		
		let section = TableSection(headerView: header, footerView: footer, models: articles)
		return section
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

public class Article: ModelProtocol, Hashable {
	public var identifier: Int {
		return id.hashValue
	}
	
	public static func == (lhs: Article, rhs: Article) -> Bool {
		return (lhs.identifier == rhs.identifier)
	}
	
	public let title: String
	public let text: String
	public let id: String = NSUUID().uuidString

	public init(title: String, text: String) {
		self.title = title
		self.text = text
	}
}

public class TableArticleCell: UITableViewCell {
	@IBOutlet public var titleLabel: UILabel?
	@IBOutlet public var subtitleLabel: UILabel?
}

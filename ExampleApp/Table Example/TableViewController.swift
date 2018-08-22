//
//  FirstViewController.swift
//  ExampleApp
//
//  Created by Daniele Margutti on 21/04/2018.
//  Copyright © 2018 FlowKit. All rights reserved.
//

import UIKit

class TableViewController: UIViewController {
	
	@IBOutlet public var tableView: UITableView?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView?.director.register(adapter: ArticleAdapter())
		self.tableView?.director.add(section: self.getWinnerSection())

		self.tableView?.director.rowHeight = .autoLayout(estimated: 100)
		self.tableView?.director.reloadData(after: { _ in
			
			return TableReloadAnimations.default()
		}, onEnd: nil)
		
	}
	
	func getWinnerSection() -> TableSection {
		let articles = (0..<7).map {
			return Article(title: "Article_Title_\($0)".loc, text: "Article_Text_\($0)".loc)
		}
		
		let header = TableSectionView<TableExampleHeaderView>()
		header.on.willDisplay = { ctx in
			guard let section = ctx.table?.director.sections[ctx.section] else { return }
			
			ctx.view?.titleLabel?.text = section.collapsed ? "Tap to expand" : "Tap to collapse"
			ctx.view?.whenTapped = {
				ctx.table?.director.reloadData(after: { (director) -> (TableReloadAnimations?) in
					section.collapsed = !section.collapsed
					return TableReloadAnimations.default()
				}, onEnd: {
					ctx.view?.titleLabel?.text = section.collapsed ? "Tap to expand" : "Tap to collapse"
				})
			}
		}
		header.on.height = { _ in
			return 150
		}
		
		let footer = TableSectionView<TableFooterExample>()
		footer.on.height = { _ in
			return 30
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

public class ArticleAdapter: TableAdapter<Article,TableArticleCell> {
	
	init() {
		super.init()
		self.on.dequeue = { ctx in
			ctx.cell?.titleLabel?.text = ctx.model.title
			ctx.cell?.subtitleLabel?.text = ctx.model.text
		}
		self.on.tap = { ctx in
			print("Tapped on article \(ctx.model.id)")
			return .deselectAnimated
		}
	}
	
}

public class Article: ModelProtocol, Hashable {
	public var hashValue: Int {
		return self.id.hashValue
	}

	public static func == (lhs: Article, rhs: Article) -> Bool {
		return (lhs.id == rhs.id)
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

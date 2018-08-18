//
//  CollectionExampleController.swift
//  ExampleApp
//
//  Created by Daniele Margutti on 21/04/2018.
//  Copyright © 2018 FlowKit. All rights reserved.
//

import UIKit
import FlowKit

class CollectionExampleController: UIViewController {
	
	@IBOutlet public var collectionView: UICollectionView?

	private var director: FlowCollectionDirector?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.director = FlowCollectionDirector(self.collectionView!)
		
		let letterAdapter = CollectionAdapter<String,LetterCell>()
		self.director?.register(adapter: letterAdapter)
		letterAdapter.on.dequeue = { ctx in
			ctx.cell?.label?.text = "\(ctx.model)"
            ctx.cell?.back?.layer.borderWidth = 2
            ctx.cell?.back?.layer.borderColor = UIColor.darkGray.cgColor
            ctx.cell?.back?.backgroundColor = UIColor.white
		}
		letterAdapter.on.didSelect = { ctx in
			print("Tapped letter \(ctx.model)")
		}
		letterAdapter.on.itemSize = { ctx in
            return CGSize(width: ctx.collectionSize!.width / 3.0, height: max(ctx.collectionSize!.width, ctx.collectionSize!.height) / 16.0)
		}
		
		
		
		let numberAdapter = CollectionAdapter<Int,NumberCell>()
		self.director?.register(adapter: numberAdapter)
		numberAdapter.on.dequeue = { ctx in
			ctx.cell?.label?.text = "#\(ctx.model)"
			ctx.cell?.back?.layer.borderWidth = 2
			ctx.cell?.back?.layer.borderColor = UIColor.darkGray.cgColor
            ctx.cell?.backgroundColor = UIColor.lightGray
		}
		numberAdapter.on.didSelect = { ctx in
			print("Tapped number \(ctx.model)")
		}
		numberAdapter.on.itemSize = { ctx in
            return CGSize.init(width: ctx.collectionSize!.width / 3.0, height: max(ctx.collectionSize!.width, ctx.collectionSize!.height) / 16.0)
		}
		
		var list: [ModelProtocol] = (0..<99).map { return $0 }
		list.append(contentsOf: ["A","B","C","D","E","F"])
		list.shuffle()
		
		let header = CollectionSectionView<CollectionHeader>()
		header.on.referenceSize = { _ in
            return CGSize(width: self.collectionView!.frame.width, height: self.collectionView!.frame.height / 8.0)
		}
		let section = CollectionSection.init(list, headerView: header)
		
		self.director?.add(section)
		self.director?.reloadData()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

extension Int: ModelProtocol {
	public var identifier: Int {
		return self
	}
	
}

extension String: ModelProtocol {
	public var identifier: Int {
		return self.hashValue
	}
	
}

public class NumberCell: UICollectionViewCell {
	@IBOutlet public var label: UILabel?
	@IBOutlet public var back: UIView?
}


public class LetterCell: UICollectionViewCell {
	@IBOutlet public var label: UILabel?
    @IBOutlet public var back: UIView?
}

extension MutableCollection {
	/// Shuffles the contents of this collection.
	mutating func shuffle() {
		let c = count
		guard c > 1 else { return }
		
		for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
			// Change `Int` in the next line to `IndexDistance` in < Swift 4.1
			let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
			let i = index(firstUnshuffled, offsetBy: d)
			swapAt(firstUnshuffled, i)
		}
	}
}

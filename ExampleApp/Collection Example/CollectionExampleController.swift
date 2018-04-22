//
//  CollectionExampleController.swift
//  ExampleApp
//
//  Created by Daniele Margutti on 21/04/2018.
//  Copyright © 2018 FlowKit. All rights reserved.
//

import UIKit

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
		}
		letterAdapter.on.didSelect = { ctx in
			print("Tapped letter \(ctx.model)")
		}
		letterAdapter.on.itemSize = { ctx in
			return CGSize.init(width: ctx.collectionSize!.width / 3.0, height: 100)
		}
		
		
		
		let numberAdapter = CollectionAdapter<Int,NumberCell>()
		self.director?.register(adapter: numberAdapter)
		numberAdapter.on.dequeue = { ctx in
			ctx.cell?.label?.text = "#\(ctx.model)"
			ctx.cell?.back?.layer.borderWidth = 2
			ctx.cell?.back?.layer.borderColor = UIColor.darkGray.cgColor
			ctx.cell?.back?.backgroundColor = UIColor.white
		}
		numberAdapter.on.didSelect = { ctx in
			print("Tapped number \(ctx.model)")
		}
		numberAdapter.on.itemSize = { ctx in
			return CGSize.init(width: ctx.collectionSize!.width / 3.0, height: 100)
		}
		
		var list: [ModelProtocol] = (0..<70).map { return $0 }
		list.append(contentsOf: ["A","B","C","D","E","F"])
		list.shuffle()
		self.director?.add(models: list)
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

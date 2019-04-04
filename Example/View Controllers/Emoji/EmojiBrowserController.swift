//
//  EmojiBrowserController.swift
//  Example
//
//  Created by dan on 04/04/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

public class EmojiBrowserController: UIViewController {
    
    @IBOutlet public var collection: UICollectionView!
    
    private var emojiList = [[String]]()
    
    private var director: FlowCollectionDirector?
    
    static func create(items: [[String]]) -> EmojiBrowserController {
        let storyboard = UIStoryboard(name: "EmojiBrowserController", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmojiBrowserController") as! EmojiBrowserController
        vc.emojiList = items
        return vc
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        director = FlowCollectionDirector(collection)
        
        // CELL ADAPTER
        let emojiAdapter = CollectionCellAdapter<String, EmojiCell> { adapter in
            adapter.events.dequeue = { ctx in
                ctx.cell?.emoji = ctx.element
            }
            adapter.events.itemSize = { ctx in
                return CGSize(width: 50, height: 50)
            }
        }
        director?.registerAdapter(emojiAdapter)
        
        
        // HEADER ADAPTER
        let headerAdapter = CollectionHeaderFooterAdapter<EmojiHeaderView>({ cfg in
            cfg.events.dequeue = { ctx in
                ctx.view?.titleLabel.text = ctx.section?.identifier ?? "-"
            }
        })
        director?.registerHeaderFooterAdapter(headerAdapter)
        
        // DATA
        for (idx, rawSection) in emojiList.enumerated() {
            let section = CollectionSection(id: "Section \(idx)" ,elements: rawSection)
            section.minimumInterItemSpacing = 2
            section.minimumLineSpacing = 2
            section.headerView = headerAdapter
            section.headerSize = CGSize(width: self.collection.frame.size.width, height: 30)
            
            director?.add(section: section)
        }
        
        director?.reload(afterUpdate: nil, completion: nil)
    }
    
    @IBAction public func shuffleAllEmoji(_ sender: Any) {
//        director?.reload(afterUpdate: { dir in
//            let shuffledEmoji = self.emojiList.shuffled()
//            dir.firstSection()?.set(models: shuffledEmoji)
//        }, completion: nil)
    }
    
    @IBAction public func shuffleSection(_ sender: Any) {
        director?.reload(afterUpdate: { dir in
            var shuffledSections = dir.sections
            shuffledSections.swapAt(0, 1)
            // let shuffledSections = dir.sections.shuffled()
            dir.set(sections: shuffledSections)
        }, completion: nil)
    }
    
}

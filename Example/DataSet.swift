//
//  DataSet.swift
//  Example
//
//  Created by dan on 03/04/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import Foundation

public class DataSet {
    
    public static let shared = DataSet()
    
    public var peoples = [ContactSingle]()
    public var companies = [ContactCompany]()
    public var emoji = [[String]]()

    private init() {
        self.peoples = try! ContactSingle.readFromFile()
        let allCompanies = try! ContactCompany.readFromFile()
        self.companies = allCompanies.map({
            $0.peoples = peoples.choose(Int.random(in: 0..<peoples.count))
            return $0
        })
        
        self.emoji = createEmojiSections(sections: 3)
    }
    
    private func createEmojiSections(sections: Int = 2, items: Int = 5) -> [[String]] {
        let emojiData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "emoji_db", ofType: "json")!))
        let emojiList = try! JSONDecoder().decode([String].self, from: emojiData)
        
        var sectionsList = [[String]]()
        for idx in 0..<sections {
            let minBounds = (idx * items)
            let subarray = emojiList[minBounds..<(minBounds + items)].shuffled()
            sectionsList.append(Array(subarray))
        }
        return sectionsList
    }
    
}

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

    private init() {
        self.peoples = try! ContactSingle.readFromFile()
        let allCompanies = try! ContactCompany.readFromFile()
        self.companies = allCompanies.map({
            $0.peoples = peoples.choose(Int.random(in: 0..<peoples.count))
            return $0
        })
    }
    
}

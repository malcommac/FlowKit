//
//  String+Localise.swift
//  FlowKit
//
//  Created by Michele Dall'Agata on 18/08/2018.
//  Copyright © 2018 FlowKit. All rights reserved.
//

import Foundation

public extension String {
    
    public var loc: String {
        return NSLocalizedString(self, comment: self)
    }
    
    public func loc(default str: String?) -> String? {
        let localized = NSLocalizedString(self, comment: self)
        if localized == self { return str }
        return localized
    }
    
    public var locUp: String {
        return NSLocalizedString(self, comment: self).uppercased()
    }
    
    public func loc(_ args: CVarArg...) -> String {
        return String(format: self.loc, locale: nil, arguments: args)
    }
    
}


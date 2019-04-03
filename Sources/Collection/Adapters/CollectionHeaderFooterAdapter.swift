//
//  CollectionHeaderFooterAdapter.swift
//  FlowKit2
//
//  Created by dan on 02/04/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

public protocol CollectionHeaderFooterAdapterProtocol {
    var modelCellType: Any.Type { get }
    
    func registerHeaderFooterViewForDirector(_ director: CollectionDirector, kind: String) -> String
    func dequeueHeaderFooterForDirector(_ director: CollectionDirector, type: String, indexPath: IndexPath) -> UICollectionReusableView?
    
    @discardableResult
    func dispatch(_ event: CollectionSectionEvents, isHeader: Bool, view: UIView?, section: Int) -> Any?
}

public extension CollectionHeaderFooterAdapterProtocol {
    
    var modelCellIdentifier: String {
        return String(describing: modelCellType)
    }
    
}

public class CollectionHeaderFooterAdapter<View: UITableViewHeaderFooterView>: CollectionHeaderFooterAdapterProtocol {
    
    
    public var modelCellType: Any.Type = View.self
    
    /// Events you can subscribe for header/footer instances.
    public var events = EventsSubscriber()
    
    public func dequeueHeaderFooterForDirector(_ director: CollectionDirector, type: String, indexPath: IndexPath) -> UICollectionReusableView? {
        let identifier = View.reusableViewIdentifier
        return director.collection?.dequeueReusableSupplementaryView(ofKind: type, withReuseIdentifier: identifier, for: indexPath)
    }
    
    public func registerHeaderFooterViewForDirector(_ director: CollectionDirector, kind: String) -> String {
        let identifier = View.reusableViewIdentifier
        if     (kind == UICollectionView.elementKindSectionHeader && director.headerReuseIDs.contains(identifier)) ||
            (kind == UICollectionView.elementKindSectionFooter && director.footerReuseIDs.contains(identifier)) {
            return identifier
        }
        
        let collection = director.collection
        switch View.reusableViewSource {
        case .fromStoryboard:
            fatalError("Cannot use storyboard to instantiate \(kind): \(View.reusableViewClass)")
            
        case .fromXib(let name, let bundle):
            let nib = UINib(nibName: name ?? identifier, bundle: bundle)
            collection?.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
            
        case .fromClass:
            collection?.register(View.reusableViewClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
            
        }
        
        return identifier
    }
    
    public func dispatch(_ event: CollectionSectionEvents, isHeader: Bool, view: UIView?, section: Int) -> Any? {
        switch event {
        case .dequeue:
            events.dequeue?(Event(isHeader: isHeader, view: view, at: section))
            
        case .referenceSize:
            return events.referenceSize?(Event(isHeader: isHeader, view: view, at: section))
            
        case .didDisplay:
            events.didDisplay?(Event(isHeader: isHeader, view: view, at: section))
            
        case .endDisplay:
            events.endDisplay?(Event(isHeader: isHeader, view: view, at: section))
            
        case .willDisplay:
            events.willDisplay?(Event(isHeader: isHeader, view: view, at: section))
            
        }
        return nil
    }
    
    
}

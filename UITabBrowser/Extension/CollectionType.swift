//
//  CollectionType.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/18.
//

import Foundation

extension Collection {
    func find(where: (Element) throws -> Bool) rethrows -> Element? {
        if let index = try self.firstIndex(where: `where`) {
            return self[index]
        } else {
            return nil
        }
    }
}

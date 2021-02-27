//
//  Tab.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/01/22.
//

import UIKit

// TODO: Consider if it should have reference of browser
struct Tab: Hashable {
    let id: BrowserID
    var type: PageType
    var title: String
    var url: URL?
    var favicon: UIImage?
    var active: Bool
    var loading: Bool
    var progress: Float
    var pinned: Bool
}

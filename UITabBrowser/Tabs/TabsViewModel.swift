//
//  TabsViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/01/22.
//

import UIKit
import Combine

class TabsViewModel: ObservableObject {
    
    @Published var tabs: [Tab] = []
    @Published var selectedIndex: Int = 0

    private let browsers = Browsers.shared

    enum Section: CaseIterable {
        case tabs
    }
    
    init() {
        // subscribe browsers
        browsers.$browsers
            .map { browsers in
                return browsers.enumerated().map {
                    let browser = $0.element
                    // set selected
                    if browser.selected {
                        self.selectedIndex = $0.offset
                    }
                    // let offset = $0.offset
                    switch browser.type {
                    case .browser:
                        return Tab(
                            id: browser.id,
                            type: .browser,
                            title: browser.title,
                            url: browser.url,
                            favicon: browser.favicon,
                            active: browser.selected,
                            loading: browser.loading,
                            progress: browser.progress,
                            pinned: browser.pinned
                        )
                    case .search:
                        return Tab(
                            id: browser.id,
                            type: .search,
                            title: NSLocalizedString("Search", comment: "in tab of search"),
                            url: nil,
                            favicon: UIImage(systemName: "magnifyingglass"),
                            active:  browser.selected,
                            loading: false,
                            progress: 1.0,
                            pinned: browser.pinned
                        )
                    }
                }
            }
            .assign(to: &$tabs)
    }
}

extension TabsViewModel {
    func select(index: Int) {
        if index >= 0 && index < tabs.count {
            browsers.select(id: tabs[index].id)
        }
    }
    
    func delete(id: BrowserID) {
        browsers.delete(id: id)
    }
    
    func reload(id: BrowserID) {
        browsers.reload(id: id)
    }
    
    func bookmark(url: URL, title: String, browserId: BrowserID) {
        Items.shared.add(
            type: .bookmark,
            title: title,
            url: url,
            keywords: "",
            browserId: browserId
        )
    }
    
    func openNewTab(url: URL) {
        browsers.insertBrowser(urlString: url.absoluteString)
    }
    
    func setPin(id: BrowserID, pinned: Bool) {
        if let browser = tabs.find(where: { $0.id == id }) {
            browsers.setPin(id: browser.id, pinned: pinned)
        }
    }
}

//
//  SearchBarViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/02.
//

import Combine
import UIKit

class SearchBarViewModel: NSObject {

    private let items = Items.shared

    @Published var url: URL? = nil
    @Published var keywords: String = ""
    @Published var currentBrowser: Browser? = nil
    @Published var isSearch = false

    override init() {
        super.init()

        let browsers = Browsers.shared

        browsers.$currentBrowser
            .assign(to: &$currentBrowser)

        browsers.$currentBrowser
            .map { $0?.url }
            .assign(to: &$url)

        browsers.$currentBrowser
            .map { $0?.type == .some(.search) }
            .assign(to: &$isSearch)

        NotificationCenter.default
            .publisher(for: SetTextInSearchBarNotification)
            .compactMap { $0.object as? String }
            .assign(to: &$keywords)
    }

    func search(_ text: String) {
        let url = text.searchURL(searchURLPrefix: Settings.shared.searchEngine.urlPrefix)
        openURL(url: url)
        if !text.isURL {
            // Save keywords
            if let currentBrowser = currentBrowser {
                items.add(
                    type: .keywords,
                    title: text,
                    url: url,
                    keywords: text,
                    browserId: currentBrowser.id
                )
            } else {
                print("Exception")
            }
        }
    }

    func openURL(url: URL) {
        guard let currentBrowser = currentBrowser else {
            return
        }
        let sharedBrowsers = Browsers.shared
        if currentBrowser.type == .search {
            // if same url tab exists...
            if let browser = Browsers.shared.browserOf(url: url) {
                // move to the tab
                sharedBrowsers.select(id: browser.id)
            } else {
                // open a new tab
                Browsers.shared.appendBrowser(urlString: url.absoluteString)
            }
            // Close search view
            if let searchViewID = sharedBrowsers.getSearchViewID() {
                sharedBrowsers.delete(id: searchViewID)
            }
        } else {
            currentBrowser.openURL(url: url)
        }
    }

    func setEnteredText(_ text: String) {
        // Update search results
        if let searchResultsController = currentBrowser?.searchResultController {
            searchResultsController.getItems(itemType: .keywords, filterText: text)
        }
    }
}

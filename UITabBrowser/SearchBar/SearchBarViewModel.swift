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
    @Published var privateMode = false
    @Published var iconType: IconType = .Magnifyingglass

    enum IconType: String {
        case Magnifyingglass = "magnifyingglass"
        case LockShieldFill = "lock.shield"
        case LockFill = "lock.fill"
        case LockSlash = "lock.slash"
        case ShieldFill = "shield.slash"
        var name: String {
            return self.rawValue
        }
    }

    override init() {
        super.init()

        let browsers = Browsers.shared

        browsers.$currentBrowser
            .assign(to: &$currentBrowser)

        $currentBrowser
            .map { $0?.url }
            .removeDuplicates()
            .assign(to: &$url)

        $currentBrowser
            .map { $0?.type == .some(.search) }
            .removeDuplicates()
            .assign(to: &$isSearch)

        $currentBrowser
            .map { $0?.privateMode ?? false }
            .removeDuplicates()
            .assign(to: &$privateMode)

        $url
            .combineLatest($privateMode)
            .combineLatest($isSearch)
            .map {
                let (url, privateMode) = $0
                let isSearch = $1
                if isSearch {
                    return .Magnifyingglass
                } else {
                    if let url = url {
                        if url.absoluteString.isSecureURL {
                            return privateMode ? .LockShieldFill : .LockFill
                        } else {
                            return privateMode ? .ShieldFill : .LockSlash
                        }
                    } else {
                        return .Magnifyingglass
                    }
                }
            }
            .assign(to: &$iconType)

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
            if let currentBrowser = currentBrowser, !currentBrowser.privateMode {
                items.add(
                    type: .keywords,
                    title: text,
                    url: url,
                    keywords: text,
                    browserId: currentBrowser.id
                )
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
            if let browser = Browsers.shared.browserOf(url: url), !currentBrowser.privateMode {
                // move to the tab
                sharedBrowsers.select(id: browser.id)
                // close search view
                if let searchViewID = sharedBrowsers.getSearchViewID() {
                    sharedBrowsers.delete(id: searchViewID)
                }
            } else {
                // open
                currentBrowser.openURL(url: url)
            }
        } else {
            // open
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

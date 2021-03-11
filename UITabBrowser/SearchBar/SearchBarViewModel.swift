//
//  SearchBarViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/02.
//

import UIKit
import Combine

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
        if let currentBrowser = currentBrowser {
            currentBrowser.openURL(url: url)
        } else {
            Browsers.shared.appendBrowser(urlString: url.absoluteString)
        }
    }
    
    func setEnteredText(_ text: String) {
        // Update search results
        if let searchResultsController = currentBrowser?.searchResultController {
            searchResultsController.getItems(itemType: .keywords, filterText: text)
        }
    }
}

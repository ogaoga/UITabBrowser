//
//  Browsers.swift
//  UITabBrowser
//
//  Created by ogaoga on 2020/12/29.
//

import Combine
import UIKit

final class Browsers: NSObject, ObservableObject {
    static var shared = Browsers()

    private var cancellables: Set<AnyCancellable> = []

    // Browsers
    @Published var browsers: [Browser] = []
    @Published var currentBrowser: Browser? = nil
    var viewControllers: [UIViewController] {
        return browsers.map { browser in
            return browser.viewController
        }
    }

    // manage selected tab

    private var selectedIndex: Int {
        return browsers.firstIndex { $0.selected } ?? 0
    }

    @Published var selectedViewController: UIViewController? = nil

    override init() {
        super.init()
        if Settings.shared.onboarding {
            initialize()
        }
    }

    func initialize() {
        // Initialize with saved data
        browsers = Settings.shared.browsers.map {
            $0.delegate = self
            return $0
        }
        if browsers.count == 0 {
            appendSearch()
        }

        // Save browsers
        $browsers
            .dropFirst()
            .compactMap { $0.count > 0 ? $0 : nil }
            .debounce(for: 5, scheduler: DispatchQueue.main)
            .assign(to: \.browsers, on: Settings.shared)
            .store(in: &cancellables)

        // Selected View Controller
        $browsers
            .compactMap {
                $0.count > 0
                    ? $0.find(where: { $0.selected })?.viewController
                    : nil
            }
            .assign(to: &$selectedViewController)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    func browserOf(url: URL) -> Browser? {
        if let index = browsers.lastIndex(where: { browser in
            browser.url?.absoluteString == url.absoluteString
        }) {
            return browsers[index]
        } else {
            return nil
        }
    }

    func appendBrowser(urlString: String) {
        appendBrowsers(urlStrings: [urlString])
    }

    func appendBrowsers(urlStrings: [String]) {
        // Delete except .browser and clear selected from existing browsers
        let currentBrowsers: [Browser] =
            browsers
            // .filter { $0.type == .browser }
            .map {
                $0.selected = false
                return $0
            }
        // Make new browsers
        let newBrowsers: [Browser] = urlStrings.enumerated().map {
            let browser = Browser(type: .browser, urlString: $0.element)
            browser.delegate = self
            return browser
        }
        // Select the last
        newBrowsers.last?.selected = true
        // Update
        browsers = currentBrowsers + newBrowsers
        updateCurrentBrowser()
    }

    func appendSearch(privateMode: Bool = false) {
        let browser = Browser(type: .search)
        browser.delegate = self
        browser.privateMode = privateMode
        browsers.append(browser)
        selectLast()
    }

    func insertBrowser(urlString: String, privateMode: Bool = false) {
        let browser = Browser(type: .browser, urlString: urlString, privateMode: privateMode)
        browser.delegate = self
        browsers.insert(browser, at: selectedIndex + 1)
        select(index: selectedIndex + 1)
    }

    func select(id: BrowserID) {
        // change selected
        browsers = browsers.map { browser in
            browser.selected = browser.id == id
            return browser
        }
        // update current browser
        updateCurrentBrowser()
    }

    private func select(index: Int) {
        if index >= 0 && index < browsers.count {
            select(id: browsers[index].id)
        }
    }

    private func selectLast() {
        select(index: browsers.count - 1)
    }

    func delete(id: BrowserID) {
        let newSelected = selectedIndex == browsers.count - 1 ? selectedIndex - 1 : selectedIndex
        browsers = browsers.filter { $0.id != id }
        if browsers.count == 0 {
            appendSearch()
        }
        select(index: newSelected)
    }

    func deleteAll(includePinned: Bool = false) {
        // Save current browser to keep it as much as possible
        let currentId = browsers.find(where: { $0.selected })?.id
        // Filter
        browsers = includePinned ? [] : browsers.filter { $0.pinned }
        // Show search view if no browser exists
        if browsers.count == 0 {
            appendSearch()
        }
        // Select tab
        if let newBrowser = browsers.find(
            where: {
                currentId != nil && $0.id == currentId
            }
        ) {
            select(id: newBrowser.id)
        } else {
            selectLast()
        }
    }

    func deleteAllPrivate() {
        // Save current browser to keep it as much as possible
        let currentId = browsers.find(where: { $0.selected })?.id
        // Filter
        browsers = browsers.filter { !$0.privateMode }
        // Show search view if no browser exists
        if browsers.count == 0 {
            appendSearch()
        }
        // Select tab
        if let newBrowser = browsers.find(
            where: {
                currentId != nil && $0.id == currentId
            }
        ) {
            select(id: newBrowser.id)
        } else {
            selectLast()
        }
    }

    /*
    func hasPrivate() -> Bool {
        return browsers.firstIndex { $0.privateMode } != nil
    }
     */

    func getSearchViewID() -> BrowserID? {
        if let index = browsers.firstIndex(where: { $0.type == .search }) {
            return browsers[index].id
        } else {
            return nil
        }
    }

    func showSearch(privateMode: Bool = false) {
        if let id = getSearchViewID() {
            // move to search
            select(id: id)
            setPrivateMode(id: id, mode: privateMode)
        } else {
            // Add search
            appendSearch(privateMode: privateMode)
        }
    }

    func reload(id: BrowserID) {
        if let browser = get(id: id) {
            browser.reload()
        }
    }

    func openURL(id: BrowserID, url: URL) {
        if let browser = get(id: id) {
            browser.openURL(url: url)
        }
    }

    func setPin(id: BrowserID, pinned: Bool) {
        if let selectedBrowser = get(id: id) {
            // Pin selected tab
            selectedBrowser.pinned = pinned

            // Keep selected ID
            let currentId = browsers[selectedIndex].id

            // Reorder
            var pinned: [Browser] = []
            var unpinned: [Browser] = []
            browsers.forEach {
                if $0.pinned {
                    pinned.append($0)
                } else {
                    unpinned.append($0)
                }
            }
            browsers = pinned + unpinned

            // Select
            if let browser = browsers.find(where: { $0.id == currentId }) {
                select(id: browser.id)
            }
        }
    }

    // private mode
    func setPrivateMode(id: BrowserID, mode: Bool = true) {
        browsers = browsers.map({ browser in
            if browser.id == id {
                browser.privateMode = mode
            }
            return browser
        })
        updateCurrentBrowser()
    }

    func get(id: BrowserID) -> Browser? {
        return browsers.find { $0.id == id }
    }

    // Update browsers to trigger subscribers
    private func updateBrowsers() {
        // Update browsers
        browsers = browsers.map { $0 }
    }

    // Update current browser to trigger subscribers
    private func updateCurrentBrowser() {
        if let browser = browsers.find(where: { $0.selected }) {
            currentBrowser = browser
        }
    }
}

extension Browsers: BrowserDelegate {
    func didUpdate(_ browser: Browser) {
        updateBrowsers()
        updateCurrentBrowser()
    }
}

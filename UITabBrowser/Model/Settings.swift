//
//  Settings.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/16.
//

import Combine
import Foundation

enum SearchEngine: String, CaseIterable {
    case google = "https://www.google.com/search?q="
    case yahoojp = "https://search.yahoo.co.jp/search?p="
    case bing = "https://www.bing.com/search?q="

    var title: String {
        switch self {
        case .google:
            return "Google"
        case .yahoojp:
            return "Yahoo! Japan"
        case .bing:
            return "Bing"
        }
    }

    var urlPrefix: String {
        return self.rawValue
    }

    static let defaultEngine: SearchEngine = .google
}

final class Settings {
    static let shared = Settings()

    enum Key: String {
        case searchEngine = "SearchEngine"
        case onboarding = "Onboarding"
    }

    private let userDefaults = UserDefaults.standard

    // MARK: - Properties

    // Search Engine
    var searchEngine: SearchEngine {
        get {
            if let value = userDefaults.string(forKey: Key.searchEngine.rawValue) {
                return SearchEngine(rawValue: value) ?? .defaultEngine
            } else {
                return .defaultEngine
            }
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.searchEngine.rawValue)
        }
    }

    // Remember tabs
    var browsers: [Browser] {
        get {
            let newBrowsers = Items.shared
                .getItems(type: .tab, filterText: "")
                .map {
                    Browser(
                        type: .browser,
                        urlString: $0.url.absoluteString,
                        title: $0.title,
                        selected: $0.selected,
                        pinned: $0.pinned
                    )
                }
            if newBrowsers.firstIndex(where: { $0.selected }) == nil {
                newBrowsers.last?.selected = true
            }
            return newBrowsers
        }
        set {
            let items = Items.shared
            items.deleteAll(itemType: .tab)
            newValue
                .filter { $0.type == .browser }
                .enumerated()
                .forEach {
                    let browser = $0.element
                    if !browser.privateMode {
                        items.add(
                            type: .tab,
                            title: browser.title,
                            url: browser.url!,
                            keywords: "",
                            browserId: browser.id,
                            selected: browser.selected,
                            pinned: browser.pinned,
                            order: $0.offset
                        )
                    }
                }
        }
    }

    var onboarding: Bool {
        get {
            return userDefaults.bool(forKey: Key.onboarding.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Key.onboarding.rawValue)
        }
    }

    // MARK: - Initialize

    init() {
        // Initialize
        userDefaults.register(defaults: [
            Key.searchEngine.rawValue: SearchEngine.defaultEngine.rawValue,
            Key.onboarding.rawValue: false,
        ])
    }
}

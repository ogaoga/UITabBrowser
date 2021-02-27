//
//  SettingsViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/15.
//

import UIKit
import Combine

class SettingsViewModel: ObservableObject {

    // MARK: - Singleton
    
    static let shared = SettingsViewModel()

    // MARK: - Private properties
    
    private let gitHubUrl = "https://github.com/ogaoga/UITabBrowser"
    private let twitterUrl = "https://twitter.com/UITabBrowser_browser"

    // MARK: - Published properties

    @Published var searchEngine: SearchEngine = .google
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"    
    
    // MARK: - Initializer & deinitializer
    
    init() {
        self.searchEngine = Settings.shared.searchEngine
    }
    
    // MARK: - Commands
    
    func setSearchEngine(_ searchEngine: SearchEngine) {
        Settings.shared.searchEngine = searchEngine
        self.searchEngine = searchEngine
    }
    
    func showGitHub() {
        Browsers.shared.appendBrowser(urlString: gitHubUrl)
    }
    
    func showTwitter() {
        Browsers.shared.appendBrowser(urlString: twitterUrl)
    }
}

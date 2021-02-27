//
//  MainViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/01.
//

import UIKit
import Combine

class MainViewModel: NSObject, ObservableObject {
    
    // MARK: - Private properties
    
    private let browsers = Browsers.shared

    // MARK: - Published properties
    
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var url: URL?
    @Published var isCloseButtonEnabled = true
    @Published var isSearchButtonEnabled = true
    @Published var barsHidden = false
    @Published var progress: Float = 0.0

    // MARK: - Initializer and deinitializer
    
    override init() {
        super.init()
        
        // Control enable/disable back/forward button
        browsers.$currentBrowser
            .map { $0?.canGoBack ?? false }
            .removeDuplicates()
            .assign(to: &$canGoBack)
        browsers.$currentBrowser
            .map { $0?.canGoForward ?? false }
            .removeDuplicates()
            .assign(to: &$canGoForward)
        // Observe URL
        browsers.$currentBrowser
            .map { $0?.url }
            .assign(to: &$url)
        
        // Scroll
        browsers.$currentBrowser
            .throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
            .compactMap { $0?.velocity }
            .map { $0.y > 0.0 }
            .assign(to: &$barsHidden)
        
        // Progress
        browsers.$currentBrowser
            .compactMap { $0?.progress }
            .map { $0 == 1.0 ? 0.0 : $0 }
            .assign(to: &$progress)
        
        // Close button
        browsers.$currentBrowser
            .compactMap { $0 }
            .map { currentBrowser in
                let browsers = self.browsers.browsers
                return !(browsers.count == 1 && currentBrowser.type == .search) && !currentBrowser.pinned
            }
            .assign(to: &$isCloseButtonEnabled)
        
        // Search button
        browsers.$currentBrowser
            .map { $0 != nil && $0!.type != .search }
            .assign(to: &$isSearchButtonEnabled)
    }
    
    // MARK: - Functions
    
    func appendBrowser(urlString: String) {
        browsers.appendBrowser(urlString: urlString)
    }
    
    func goBack() {
        let vc = browsers.selectedViewController
        if vc is WebViewController {
            (vc as! WebViewController).webView.goBack()
        }
    }
    
    func goForward() {
        let vc = browsers.selectedViewController
        if vc is WebViewController {
            (vc as! WebViewController).webView.goForward()
        }
    }
    
    // Close the tab
    func close() {
        if let id = browsers.currentBrowser?.id {
            browsers.delete(id: id)
        }
    }
    
    func closeAll() {
        browsers.deleteAll()
    }
    
    func showSearch() {
        browsers.showSearch()
    }
}

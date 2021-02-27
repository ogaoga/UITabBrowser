//
//  Browsers.swift
//  UITabBrowser
//
//  Created by ogaoga on 2020/12/29.
//

import UIKit
import WebKit
import Combine

// Protocol for delegate

protocol BrowserDelegate: AnyObject {
    func didUpdate(_ browser: Browser)
}

extension BrowserDelegate {
    func didUpdate(_ browser: Browser) {}
}

typealias BrowserID = UUID

class Browser {
    var viewController: UIViewController! = nil
    let id: BrowserID = UUID()

    // values
    @Published var url: URL? = nil
    @Published var selected: Bool = false
    var type: PageType
    var title = ""
    var pinned = false
    var loading = false
    var progress: Float = 0.0
    var canGoBack = false
    var canGoForward = false
    var favicon: UIImage? = nil {
        didSet {
            delegate?.didUpdate(self)
        }
    }
    var offset = CGPoint(x: 0.0, y: 0.0)
    var velocity = CGPoint(x: 0.0, y: 0.0)
    
    @Published private var faviconLoader: FaviconLoader = FaviconLoader()
    
    // delegate
    weak var delegate: BrowserDelegate?

    // Combine
    private var cancellables: Set<AnyCancellable> = []
    
    init(type: PageType, urlString: String? = nil, selected: Bool = false, pinned: Bool = false) {
        self.type = type
        self.selected = selected
        self.pinned = pinned
        switch type {
        case .browser:
            // Browser
            if let urlString = urlString, let url = URL(string: urlString) {
                self.url = url
                let webVC = WebViewController()
                webVC.delegate = self
                webVC.load(url: url)
                self.viewController = webVC
            } else {
                fatalError("URL is invalid: \(urlString ?? "nil")")
            }
        case .search:
            // Search Result
            let storyboard = UIStoryboard(name: "SearchResults", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! SearchResultsController
            vc.initialItemType = .keywords
            self.viewController = vc
        }
        
        // Observe url to fetch favicon
        $url
            .compactMap { $0 }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { url in
                // fetch favicon
                self.faviconLoader.request(url: url)
            })
            .store(in: &cancellables)
        
        // Observe favicon
        faviconLoader.$image
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.favicon = $0
            })
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    private func update() {
        delegate?.didUpdate(self)
    }
    
    func openURL(url: URL) {
        if let vc = self.viewController {
            switch vc {
            case is WebViewController:
                (vc as! WebViewController).load(url: url)
            case is SearchResultsController:
                // Replace with WebView
                self.viewController.view.isHidden = true
                self.viewController = nil
                self.type = .browser
                self.url = url
                let webVC = WebViewController()
                webVC.delegate = self
                webVC.load(url: url)
                self.viewController = webVC
            default:
                fatalError(vc.debugDescription)
            }
        }
    }
    
    func scrollToTop() {
        if let vc = self.viewController, vc is WebViewController {
            (vc as! WebViewController).webView.scrollView.setContentOffset(
                CGPoint(x: 0.0, y: 0.0), animated: true
            )
        }
    }
    
    func reload() {
        if let vc = self.viewController, type == .browser {
            (vc as! WebViewController).webView.reload()
        }
    }
}

extension Browser: WebViewControllerDelegate {
    func webViewController(_ viewController: WebViewController, didTitleUpdate title: String) {
        self.title = title
        update()
    }
    
    func webViewController(_ viewController: WebViewController, didURLUpdate url: URL) {
        self.url = url
        update()
    }
    
    func webViewController(_ viewController: WebViewController, didLoadingUpdate loading: Bool) {
        self.loading = loading
        update()
    }
    
    func webViewController(_ viewController: WebViewController, didProgressUpdate progress: Float) {
        self.progress = progress
        update()
    }
    
    func webViewController(_ viewController: WebViewController, didCanGoBackUpdate canGoBack: Bool) {
        self.canGoBack = canGoBack
        update()
    }
    
    func webViewController(_ viewController: WebViewController, didCanGoForwardUpdate canGoForward: Bool) {
        self.canGoForward = canGoForward
        update()
    }
    
    func webViewController(_ viewController: WebViewController, openNewTab url: URL) {
        Browsers.shared.insertBrowser(urlString: url.absoluteString)
    }
    
    func webViewController(_ viewController: WebViewController, didScroll offset: CGPoint) {
        self.offset = offset
        update()
    }

    func webViewController(_ viewController: WebViewController, WillEndDragging velocity: CGPoint) {
        self.velocity = velocity
    }
    
    func webViewControllerDidFinishNavigation(_ viewController: WebViewController) {
        // Save history
        if let webView = viewController.webView, let url = webView.url, let title = webView.title {
            Items.shared.add(
                type: .history, title: title, url: url, keywords: "", browserId: id
            )
        }
    }
}

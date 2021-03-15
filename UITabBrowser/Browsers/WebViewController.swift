//
//  WebViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2020/12/27.
//

import UIKit
import WebKit

// Delegate protocol
protocol WebViewControllerDelegate: AnyObject {
    func webViewController(_ viewController: WebViewController, didTitleUpdate title: String)
    func webViewController(_ viewController: WebViewController, didURLUpdate url: URL)
    func webViewController(_ viewController: WebViewController, didProgressUpdate progress: Float)
    func webViewController(_ viewController: WebViewController, didLoadingUpdate loading: Bool)
    func webViewController(_ viewController: WebViewController, didCanGoBackUpdate loading: Bool)
    func webViewController(_ viewController: WebViewController, didCanGoForwardUpdate loading: Bool)
    func webViewController(_ viewController: WebViewController, openNewTab url: URL)
    func webViewController(_ viewController: WebViewController, didScroll offset: CGPoint)
    func webViewController(_ viewController: WebViewController, WillEndDragging velocity: CGPoint)
    func webViewController(_ viewController: WebViewController, openExternalApp url: URL)
    func webViewControllerDidFinishNavigation(_ viewController: WebViewController)
}

// Set optional
extension WebViewControllerDelegate {
    func webViewController(_ viewController: WebViewController, didTitleUpdate title: String) {}
    func webViewController(_ viewController: WebViewController, didURLUpdate url: URL) {}
    func webViewController(_ viewController: WebViewController, didProgressUpdate progress: Float) {
    }
    func webViewController(_ viewController: WebViewController, didCanGoBackUpdate loading: Bool) {}
    func webViewController(_ viewController: WebViewController, didCanGoForwardUpdate loading: Bool)
    {}
    func webViewController(_ viewController: WebViewController, openNewTab url: URL) {}
    func webViewController(_ viewController: WebViewController, didScroll offset: CGPoint) {}
    func webViewController(_ viewController: WebViewController, WillEndDragging velocity: CGPoint) {
    }
    func webViewController(_ viewController: WebViewController, openExternalApp url: URL) {}
    func webViewControllerDidFinishNavigation(_ viewController: WebViewController) {}
}

struct KeyPath {
    static let title = "title"
    static let estimatedProgress = "estimatedProgress"
    static let url = "URL"
    static let loading = "loading"
    static let canGoBack = "canGoBack"
    static let canGoForward = "canGoForward"
}

class WebViewController: UIViewController {

    var webView: WKWebView! = nil
    weak var delegate: WebViewControllerDelegate?

    func load(url: URL) {

        // instance
        if webView == nil {
            let config = WKWebViewConfiguration()
            webView = WKWebView(frame: .zero, configuration: config)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.scrollView.scrollsToTop = true
            webView.scrollView.delegate = self
            webView.addObserver(self, forKeyPath: KeyPath.title, options: .new, context: nil)
            webView.addObserver(
                self,
                forKeyPath: KeyPath.estimatedProgress,
                options: .new,
                context: nil
            )
            webView.addObserver(self, forKeyPath: KeyPath.url, options: .new, context: nil)
            webView.addObserver(self, forKeyPath: KeyPath.loading, options: .new, context: nil)
            webView.addObserver(self, forKeyPath: KeyPath.canGoBack, options: .new, context: nil)
            webView.addObserver(self, forKeyPath: KeyPath.canGoForward, options: .new, context: nil)
            view = webView
        }

        // load
        if webView != nil {
            webView.allowsBackForwardNavigationGestures = true
            webView.load(URLRequest(url: url))
        }
    }

    deinit {
        if webView != nil {
            webView.removeObserver(self, forKeyPath: KeyPath.canGoForward, context: nil)
            webView.removeObserver(self, forKeyPath: KeyPath.canGoBack, context: nil)
            webView.removeObserver(self, forKeyPath: KeyPath.loading, context: nil)
            webView.removeObserver(self, forKeyPath: KeyPath.url, context: nil)
            webView.removeObserver(self, forKeyPath: KeyPath.estimatedProgress, context: nil)
            webView.removeObserver(self, forKeyPath: KeyPath.title, context: nil)
            webView = nil
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        switch keyPath {
        case KeyPath.title:
            if let title = change?[.newKey] as? String {
                delegate?.webViewController(
                    self,
                    didTitleUpdate: title.isEmpty ? webView.url?.absoluteString ?? "" : title
                )
            }
        case KeyPath.estimatedProgress:
            if let progress = change?[.newKey] as? Double {
                delegate?.webViewController(self, didProgressUpdate: Float(progress))
            }
        case KeyPath.url:
            if let url = change?[.newKey] as? URL {
                delegate?.webViewController(self, didURLUpdate: url)
            }
        case KeyPath.loading:
            if let loading = change?[.newKey] as? Bool {
                delegate?.webViewController(self, didLoadingUpdate: loading)
            }
        case KeyPath.canGoBack:
            if let canGoBack = change?[.newKey] as? Bool {
                delegate?.webViewController(self, didCanGoBackUpdate: canGoBack)
            }
        case KeyPath.canGoForward:
            if let canGoForward = change?[.newKey] as? Bool {
                delegate?.webViewController(self, didCanGoForwardUpdate: canGoForward)
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

extension WebViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {

        // URL
        guard let url = navigationAction.request.url else {
            return nil
        }

        // open new tab if target="_blank"
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            delegate?.webViewController(self, openNewTab: url)
            return nil
        }

        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        // show alert
        let controller = UIAlertController(
            title: webView.url?.host ?? "",
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        }
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // show confirm
        let controller = UIAlertController(
            title: webView.url?.host ?? "",
            message: message,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        }
        controller.addAction(cancelAction)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        // show prompt
        let controller = UIAlertController(
            title: webView.url?.host ?? "",
            message: prompt,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let textField = controller.textFields?.first {
                completionHandler(textField.text)
            } else {
                completionHandler("")
            }
        }
        controller.addTextField { $0.text = defaultText }
        controller.addAction(cancelAction)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
}

extension WebViewController: WKNavigationDelegate {

    private func showAlert(message: String, completionHandler: (() -> Void)? = nil) {
        let controller = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler?()
        }
        controller.addAction(action)
        present(controller, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {

        // Handle special schemes
        if let url = navigationAction.request.url {
            let schemes = URLSchema.urlSchemas
            if schemes.contains(url.scheme ?? "") {
                // Open external app
                let app = UIApplication.shared
                app.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                // Call delegate
                delegate?.webViewController(self, openExternalApp: url)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webViewControllerDidFinishNavigation(self)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let error = error as NSError
        if error.domain == NSURLErrorDomain && error.code == -999 {
            return
        }
        showAlert(message: error.localizedDescription) {
            webView.stopLoading()
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let error = error as NSError
        // Avoid show an alert when opening a universal link
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }
        showAlert(message: error.localizedDescription) {
            webView.stopLoading()
        }
    }
}

extension WebViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.webViewController(self, didScroll: scrollView.contentOffset)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        delegate?.webViewController(self, WillEndDragging: velocity)
    }
}

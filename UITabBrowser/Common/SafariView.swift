//
//  SafariView.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/26.
//

import Foundation
import SafariServices

func showSafariView(parent: UIViewController, url: URL, entersReaderIfAvailable: Bool = false) {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = entersReaderIfAvailable
    let vc = SFSafariViewController(url: url, configuration: config)
    vc.modalPresentationStyle = .automatic
    parent.present(vc, animated: true)
}

func showPrivacyPolicy(parent: UIViewController) {
    showSafariView(
        parent: parent,
        url: URL(string: "https://www.ogaoga.org/?page_id=887")!,
        entersReaderIfAvailable: true
    )
}

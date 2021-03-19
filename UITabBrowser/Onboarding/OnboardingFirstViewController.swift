//
//  OnboardingFirstViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/26.
//

import UIKit

class OnboardingFirstViewController: UIViewController, UISearchBarDelegate {

    @IBAction func privacyPolicy(_ sender: Any) {
        showPrivacyPolicy(parent: self)
    }
}

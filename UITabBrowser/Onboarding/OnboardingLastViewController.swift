//
//  OnboardingLastViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/26.
//

import UIKit

class OnboardingLastViewController: UIViewController, UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        dismiss(animated: true)
        return false
    }
}

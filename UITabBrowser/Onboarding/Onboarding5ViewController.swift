//
//  Onboarding5ViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/26.
//

import UIKit

class Onboarding5ViewController: UIViewController, UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        dismiss(animated: true)
        return false
    }
}

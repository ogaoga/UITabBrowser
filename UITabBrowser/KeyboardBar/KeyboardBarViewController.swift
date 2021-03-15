//
//  KeyboardBarViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/03/08.
//

import UIKit

class KeyboardBarViewController: UIViewController {

    @IBAction func cancelTextInput(_ sender: Any) {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    @IBAction func pasteText(_ sender: Any) {
        UIApplication.shared.sendAction(
            #selector(UIResponder.paste(_:)),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

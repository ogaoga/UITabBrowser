//
//  String+URL.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/07.
//

import Foundation
import UIKit

extension String {
    // URL Encode
    // https://e-joint.jp/404/
    func urlEncode() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    // Return valid URL
    func validURL() -> URL? {
        if !self.contains(".") {
            return nil
        }
        if self.starts(with: "https://") || self.starts(with: "http://") {
            if let url = URL(string: self), UIApplication.shared.canOpenURL(url) {
                return url
            } else {
                return nil
            }
        } else if let url = URL(string: "https://\(self)"), UIApplication.shared.canOpenURL(url) {
            return url
        } else {
            return nil
        }
    }
    
    // Check if the scheme is HTTPS
    var isSecureURL: Bool {
        return self.lowercased().starts(with: "https://")
    }
}

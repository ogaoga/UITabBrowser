//
//  FaviconLoader.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/20.
//

import UIKit
import Combine

class FaviconLoader : ObservableObject {

    private let defaultImage = UIImage(systemName: "globe")!
    private let imageLoader: ImageLoader
    
    @Published var image : UIImage
    
    init() {
        imageLoader = ImageLoader(defaultImage: defaultImage)
        image = defaultImage
    }
    
    func request(url: URL) {
        // Request
        if let scheme = url.scheme, let host = url.host {
            imageLoader.request(url: "\(scheme)://\(host)/favicon.ico")
        }
        
        // Subscribe
        imageLoader.$image
            .assign(to: &$image)
    }
}

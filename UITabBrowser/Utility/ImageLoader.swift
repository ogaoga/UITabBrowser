//
//  ImageLoader.swift
//  UITabBrowser
//
//  Created by ogaoga on 2019/09/13.
//

import Foundation
import UIKit
import Combine

final class ImageCache : NSCache<AnyObject, AnyObject> {
    static let shared = ImageCache()
    subscript(url: String) -> UIImage? {
        get {
            return self.object(forKey: url as AnyObject) as? UIImage
        }
        set(image) {
            if let image = image {
                self.setObject(image, forKey: url as AnyObject)
            } else {
                self.removeObject(forKey: url as AnyObject)
            }
        }
    }
}

enum ImageLoaderStatus {
    case notLoaded
    case loading
    case loaded
    case failed
}

class ImageLoader : ObservableObject {
    
    @Published var image : UIImage
    private var cancellable : AnyCancellable? = nil
    var status: ImageLoaderStatus
    private let defaultImage: UIImage
    
    convenience init() {
        self.init(defaultImage: UIImage())
    }
    
    init(defaultImage: UIImage) {
        self.status = .notLoaded
        self.image = defaultImage
        self.defaultImage = defaultImage
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    func request(url urlString: String) -> Void {
        status = .notLoaded
        guard let url = URL(string: urlString) else {
            print("URL is not correct.")
            return
        }
        if let cachedImage = ImageCache.shared[urlString] {
            status = .loaded
            self.image = cachedImage
        } else {
            status = .loading
            let request = URLRequest(url: url)
            cancellable = URLSession.shared.dataTaskPublisher(for: request)
                .map {
                    return $0.data
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                        self.status = .failed
                    }
                }, receiveValue: { value in
                    if let image = UIImage(data: value) {
                        self.status = .loaded
                        self.image = image
                        ImageCache.shared[urlString] = image
                    } else {
                        self.status = .failed
                        self.image = self.defaultImage
                    }
                })
        }
    }
}

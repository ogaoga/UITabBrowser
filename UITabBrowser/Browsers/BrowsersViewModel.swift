//
//  BrowsersViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/01/31.
//

import UIKit
import Combine

class BrowsersViewModel: NSObject, ObservableObject {

    // MARK: - properties
    
    @Published private var selectedIndex = 0 {
        willSet {
            lastSelected = selectedIndex
        }
    }
    private var lastSelected = 0
    var direction: UIPageViewController.NavigationDirection {
        get {
            return selectedIndex - lastSelected >= 0 ? .forward : .reverse
        }
    }
    
    @Published var selectedViewController: UIViewController? = nil
    
    private let browsers = Browsers.shared
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - initializer / deinitializer
    
    override init() {
        super.init()
        
        // Subscribe selected
        browsers.$browsers
            .map { browsers in
                return browsers.firstIndex { $0.selected } ?? 0
            }
            .sink(receiveValue: { [weak self] in self?.selectedIndex = $0 })
            .store(in: &cancellables)
        
        // Selected View Controller
        browsers.$selectedViewController
            .sink { [weak self] in self?.selectedViewController = $0 }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - data source

extension BrowsersViewModel: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return browsers.browsers.count
    }
}

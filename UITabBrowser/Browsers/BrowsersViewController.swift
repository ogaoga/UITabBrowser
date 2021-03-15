//
//  BrowsersViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2020/12/27.
//

import Combine
import UIKit

class BrowsersViewController: UIPageViewController {

    private let viewModel = BrowsersViewModel()

    // MARK: - Initializers

    init() {
        // Initialize
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [:]
        )

        // Set data source
        dataSource = viewModel
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Combine

    private var cancellables: Set<AnyCancellable> = []
    deinit {
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable horizontal bounces
        let scrollView = (view.subviews[0] as! UIScrollView)
        scrollView.bounces = false
        scrollView.scrollsToTop = false

        // Subscribe changing tab
        viewModel.$selectedViewController
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedVC in
                if let self = self {
                    self.setViewControllers(
                        [selectedVC],
                        direction: self.viewModel.direction,
                        animated: true
                    )
                }
            }
            .store(in: &cancellables)
    }
}

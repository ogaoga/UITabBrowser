//
//  MainViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2020/12/27.
//

import UIKit
import Combine

class MainViewController: UIViewController {

    // MARK: - Views

    var browsersViewController = BrowsersViewController()
    var searchBar = SearchBar()

    // MARK: - Private properties
    
    private var cancellables: Set<AnyCancellable> = []
    private var viewModel = MainViewModel()

    // MARK: - Outlets
    
    @IBOutlet weak var pageView: UIView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var progressBar: UIProgressView!

    // MARK: - Actions
    
    @IBAction func showSearch(_ sender: Any) {
        viewModel.showSearch()
    }
    
    @IBAction func goBack(_ sender: Any) {
        viewModel.goBack()
    }
    
    @IBAction func goForward(_ sender: Any) {
        viewModel.goForward()
    }
    
    @IBAction func close(_ sender: Any) {
        self.viewModel.close()
    }
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Search
        navigationItem.titleView = searchBar
        
        // Settings
        let title = NSLocalizedString("Settings", comment: "Title of settings")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: title,
            image: UIImage(systemName: "ellipsis"),
            primaryAction: UIAction(title: title, attributes: []) { action in
                self.performSegue(withIdentifier: "SettingsSegue", sender: nil)
            }
        )

        // Browsers View
        browsersViewController.view.frame = pageView.bounds
        pageView.addSubview(browsersViewController.view)
        
        // Control enable/disable back/forward button
        viewModel.$canGoBack
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: backButton)
            .store(in: &cancellables)
        viewModel.$canGoForward
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: forwardButton)
            .store(in: &cancellables)

        // Control bars
        viewModel.$barsHidden
            .receive(on: DispatchQueue.main)
            .sink { hidden in
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: [],
                    animations: {
                        self.navigationController?.setNavigationBarHidden(hidden, animated: true)
                        self.navigationController?.setToolbarHidden(hidden, animated: true)
                    },
                    completion: nil
                )
            }
            .store(in: &cancellables)
        
        // Close button
        viewModel.$isCloseButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: closeButton)
            .store(in: &cancellables)
        
        // Search button
        viewModel.$isSearchButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: searchButton)
            .store(in: &cancellables)

        // Progress
        viewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { progress in
                self.progressBar.progress = progress
                self.progressBar.isHidden = progress == 0.0
            })
            .store(in: &cancellables)
        
        // pull down menu on close button
        configureCloseMenu()
        
        // Onboarding
        if !Settings.shared.onboarding {
            performSegue(withIdentifier: "OnboardingSegue", sender: self)
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        pageView.subviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - Close menu

extension MainViewController {
    func configureCloseMenu() {
        let actions = [
            UIAction(
                title: NSLocalizedString("Close", comment: "in Context Menu of Close button"),
                image: UIImage(systemName: "clear"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [],
                state: .off,
                handler: { action in
                    self.viewModel.close()
                }
            ),
            UIAction(
                title: NSLocalizedString("Close All", comment: "in Context Menu of Close button"),
                image: UIImage(systemName: "clear.fill"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [.destructive],
                state: .off,
                handler: { action in
                    self.viewModel.closeAll()
                }
            ),
        ]
        closeButton.menu = UIMenu(
            title: "", image: nil, identifier: nil,
            options: .displayInline, children: actions
        )
    }
}

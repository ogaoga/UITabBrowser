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
    private var isKeyboardHidden = true

    // MARK: - Outlets
    
    @IBOutlet weak var pageView: UIView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var keyboardBar: UIView!
    @IBOutlet weak var keyboardBarOffset: NSLayoutConstraint!
    
    // MARK: - Actions
    
    @IBAction func showSearch(_ sender: Any) {
        if viewModel.isSearchView {
            searchBar.becomeFirstResponder()
        } else {
            viewModel.showSearch()
        }
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

        // Progress
        viewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { progress in
                self.progressBar.progress = progress
                self.progressBar.isHidden = progress == 0.0
            })
            .store(in: &cancellables)
        
        // Keyboard
        configureKeyboardHandling()
        
        // pull down menu on close button
        configureCloseMenu()
        configureSearchMenu()
        
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
                handler: { _ in
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
    
    func configureSearchMenu() {
        let actions = [
            UIAction(title: NSLocalizedString("Search", comment: "in Context Menu of Search button"),
                     image: UIImage(systemName: "magnifyingglass"),
                     identifier: nil,
                     discoverabilityTitle: nil,
                     attributes: [],
                     state: .off,
                     handler: { _ in
                        self.showSearch(self)
                     }
            ),
            UIAction(title: NSLocalizedString("Search from Clipboard", comment: "in Context Menu of Search button"),
                     image: UIImage(systemName: "doc.on.clipboard"),
                     identifier: nil,
                     discoverabilityTitle: nil,
                     attributes: [],
                     state: .off,
                     handler: { _ in
                        self.viewModel.searchFromClipboard()
                     }
            ),
        ]
        searchButton.menu = UIMenu(
            title: "", image: nil, identifier: nil,
            options: .displayInline, children: actions
        )
    }
}

// MARK: - Keyboard bar handling

extension MainViewController {
    private func configureKeyboardHandling() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .receive(on: DispatchQueue.main)
            .sink {
                self.keyboardBar.isHidden = !self.searchBar.editing
                if self.isKeyboardHidden {
                    self.animateWithKeyboard(notification: $0) { keyboardFrame in
                        self.keyboardBarOffset.constant = keyboardFrame.size.height
                    }
                } else {
                    if let keyboardFrame = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        self.keyboardBarOffset.constant = keyboardFrame.size.height
                    }
                }
                self.isKeyboardHidden = false
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification, object: nil)
            .receive(on: DispatchQueue.main)
            .sink {
                self.animateWithKeyboard(notification: $0) { keyboardFrame in
                    self.keyboardBarOffset.constant = 0.0
                } completion: { _ in
                    self.isKeyboardHidden = true
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardDidHideNotification, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.keyboardBar.isHidden = true
                self.isKeyboardHidden = true
            }
            .store(in: &cancellables)
    }
    
    private func animateWithKeyboard(
        notification: Notification,
        animations: ((_ keyboardFrame: CGRect) -> Void)?,
        completion: ((_ animatingPosition: UIViewAnimatingPosition?) -> Void)? = nil
    ) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! Int
        if duration > .zero {
            let animator = UIViewPropertyAnimator(
                duration: duration,
                curve: UIView.AnimationCurve(rawValue: curve)!,
                animations: {
                    animations?(keyboardFrame)
                    self.view?.layoutIfNeeded()
                }
            )
            if completion != nil {
                animator.addCompletion(completion!)
            }
            animator.startAnimation()
        } else {
            animations?(keyboardFrame)
            completion?(nil)
        }
    }
}

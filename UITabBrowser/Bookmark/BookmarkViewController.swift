//
//  BookmarkViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/11.
//

import Combine
import UIKit

class BookmarkViewController: UIViewController {

    typealias Scope = BookmarkViewModel.Scope

    // MARK: - Private properties

    private let viewModel = BookmarkViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private var searchResultsController: SearchResultsController? = nil

    // MARK: - Outlet

    @IBOutlet weak var deleteAllButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    // MARK: - Action

    @IBAction func comfirmDeleteAll(_ sender: Any) {
        // Show action sheet
        let alert = UIAlertController(
            title: nil,
            message: String(
                format: NSLocalizedString(
                    "Are you sure you want to delete all %@ items?",
                    comment: "Confirmation in bookmark view"
                ),
                viewModel.scope.title
            ),
            preferredStyle: .actionSheet
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Delete All",
                    comment: "Alert item of delete all"
                ),
                style: .destructive
            ) { action in
                self.viewModel.deleteAll(scope: self.viewModel.scope)
            }
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Cancel",
                    comment: "Alert item of delete all"
                ),
                style: .cancel
            )
        )
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true) {
            // Set keywords (temporary implementation)
            Items.shared.setType(.keywords)
        }
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearchController()

        // Title
        viewModel.$scope
            .receive(on: DispatchQueue.main)
            .map { $0.title }
            .sink(receiveValue: { [weak self] in
                self?.navigationItem.title = $0
            })
            .store(in: &cancellables)

        // Delete button
        viewModel.$isDeleteAllButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: deleteAllButton)
            .store(in: &cancellables)

        // Query
        viewModel.$scope
            .combineLatest(viewModel.$enteredText)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .map {
                var type: ItemType
                switch $0 {
                case .bookmark:
                    type = .bookmark
                case .history:
                    type = .history
                case .search:
                    type = .keywords
                }
                return (type, $1)
            }
            .receive(on: DispatchQueue.main)
            .sink { (type, filter) in
                self.searchResultsController?.getItems(itemType: type, filterText: filter)
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Configurations

    private func configureSearchController() {
        let searchController = UISearchController(
            searchResultsController: nil
        )
        searchController.searchBar.scopeButtonTitles = Scope.titles
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.showsSearchResultsController = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }
}

// MARK: - Storyboard

extension BookmarkViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SearchResultsSegue" {
            searchResultsController = segue.destination as? SearchResultsController
            // Set initial type
            searchResultsController?.initialItemType = .bookmark
            // Set delegate to handle tapping an item in the search result
            searchResultsController?.delegate = self
        }
    }
}

// MARK: - Search bar delegate

extension BookmarkViewController: UISearchBarDelegate {
    // Handle the selection of segmented control
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.setScope(scope: Scope(rawValue: selectedScope) ?? .bookmark)
    }
    // Handle search field
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.setEnteredText(searchText)
    }
    // Manage the state of Done button according to editing state of search field
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        doneButton.isEnabled = !searchBar.searchTextField.isEditing
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        doneButton.isEnabled = !searchBar.searchTextField.isEditing
    }
}

// MARK: - Search Results Controller Delegate

extension BookmarkViewController: SearchResultsControllerDelegate {
    func searchResultsController(_ controller: SearchResultsController, didSelect item: Item) {
        // Dismiss
        dismiss(animated: true) {
            // Open selected
            let browsers = Browsers.shared
            guard let currentBrowser = browsers.currentBrowser else {
                return
            }
            let url = item.url
            if let browser = browsers.browserOf(url: url) {
                // Close if the current tab is search view
                if currentBrowser.type == .search {
                    browsers.delete(id: currentBrowser.id)
                }
                // Select the tab
                browsers.select(id: browser.id)
            } else {
                if currentBrowser.type == .search {
                    // open in the current tab
                    currentBrowser.openURL(url: item.url)
                } else {
                    // open new tab
                    browsers.appendBrowser(urlString: url.absoluteString)
                }
            }
        }
        // Add the item to keywords
        if item.type == .keywords {
            Items.shared.add(
                type: .keywords,
                title: item.title,
                url: item.url,
                keywords: item.keywords,
                browserId: item.browserId
            )
        }
    }
}

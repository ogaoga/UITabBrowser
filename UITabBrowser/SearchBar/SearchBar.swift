//
//  SearchBar.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/02.
//

import Combine
import UIKit

class SearchBar: UISearchBar {

    typealias IconType = SearchBarViewModel.IconType

    private let viewModel = SearchBarViewModel()
    private var cancellables: Set<AnyCancellable> = []

    private var shouldKeepUrl = true
    @Published var editing = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Delegate
        delegate = self

        // Customize
        keyboardType = .webSearch
        autocapitalizationType = .none
        enablesReturnKeyAutomatically = true
        showsBookmarkButton = false
        placeholder = NSLocalizedString(
            "Search keywords or URL",
            comment: "Placeholder of Search Bar"
        )

        // Show URL in searchBar
        viewModel.$url
            .map { $0?.absoluteString ?? "" }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.text = $0
            })
            .store(in: &cancellables)

        // Icon
        viewModel.$iconType
            .removeDuplicates()
            .combineLatest($editing)
            .combineLatest(viewModel.$privateMode)
            .receive(on: DispatchQueue.main)
            .sink {
                let (iconType, editing) = $0
                let privateMode = $1
                self.setImage(
                    UIImage(systemName: editing ? IconType.Magnifyingglass.name : iconType.name)!
                        .withTintColor(
                            UIColor(
                                named: privateMode
                                    ? "SearchBarTextPrivateMode" : "SearchBarTextNormalMode"
                            )!,
                            renderingMode: .alwaysOriginal
                        ),
                    for: .search,
                    state: .normal
                )
            }
            .store(in: &cancellables)

        // focus the text field when switch to search page
        viewModel.$currentBrowser
            .removeDuplicates(by: { (a, b) in
                return a?.id == b?.id && a?.url == b?.url
            })
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { browser in
                if browser.type == .search {
                    self.becomeFirstResponder()
                } else {
                    self.resignFirstResponder()
                }
            }
            .store(in: &cancellables)

        // Set keywords form others
        viewModel.$keywords
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] text in
                self?.text = text
                self?.becomeFirstResponder()
            })
            .store(in: &cancellables)

        viewModel.$privateMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] privateMode in
                self?.searchTextField.backgroundColor = UIColor(
                    named: privateMode
                        ? "SearchBarBackgroundPrivateMode" : "SearchBarBackgroundNormalMode"
                )
                self?.searchTextField.textColor = UIColor(
                    named: privateMode ? "SearchBarTextPrivateMode" : "SearchBarTextNormalMode"
                )
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

extension SearchBar: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty
        {
            if !text.isURL {
                // Set url to search bar if the enterred text is not url
                searchBar.text =
                    text.searchURL(
                        searchURLPrefix: Settings.shared.searchEngine.rawValue
                    ).absoluteString
            }
            viewModel.search(text)
            shouldKeepUrl = false
            searchBar.resignFirstResponder()
            // Reset keywords
            Items.shared.setFilterText("")
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.editing = false
        if shouldKeepUrl {
            // TODO: consider how to handle here
            self.text = viewModel.url?.absoluteString ?? ""
        }
        shouldKeepUrl = true
        // Reset filter text
        viewModel.setEnteredText("")
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.editing = true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.setEnteredText(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

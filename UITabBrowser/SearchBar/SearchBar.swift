//
//  SearchBar.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/02.
//

import UIKit
import Combine

class SearchBar: UISearchBar {

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
            .receive(on: DispatchQueue.main)
            .map { $0?.absoluteString ?? "" }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] in
                self?.text = $0
            })
            .store(in: &cancellables)
        
        // Icon
        viewModel.$url
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.absoluteString }
            .sink { urlString in
                self.setImage(
                    UIImage(
                        systemName: urlString.isSecureURL ? "lock.fill" : "lock.slash"
                    ),
                    for: .search,
                    state: .normal
                )
            }
            .store(in: &cancellables)
        viewModel.$isSearch
            .combineLatest($editing)
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .map { (isSearch, editing) -> String in
                if isSearch || editing {
                    return "magnifyingglass"
                } else {
                    if let isSecureURL = self.text?.isSecureURL, isSecureURL {
                        return "lock.fill"
                    } else {
                        return "lock.slash"
                    }
                }
            }
            .sink { name in
                self.setImage(
                    UIImage(systemName: name),
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
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] text in
                self?.text = text
                self?.becomeFirstResponder()
            })
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
        if let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
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

//
//  SearchEngineViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/15.
//

import UIKit
import Combine

class SearchEngineViewController: UITableViewController {
    
    // MARK: - Private properties

    private let viewModel = SettingsViewModel.shared
    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.$searchEngine
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchEngine.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchEngineCell", for: indexPath)

        let engine = SearchEngine.allCases[indexPath.row]
        cell.textLabel?.text = engine.title
        cell.detailTextLabel?.text = engine.urlPrefix
        cell.accessoryType = engine == viewModel.searchEngine ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.setSearchEngine(SearchEngine.allCases[indexPath.row])
        /*
        // If you want to go back to parent automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationController?.popViewController(animated: true)
        }
         */
    }
}

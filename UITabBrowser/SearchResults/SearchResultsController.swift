//
//  SearchResultsController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/06.
//

import UIKit
import Combine

// Delegate protocol
protocol SearchResultsControllerDelegate: AnyObject {
    func searchResultsController(_ controller: SearchResultsController, didSelect item: Item)
}

// Set optional
extension SearchResultsControllerDelegate {
    func searchResultsController(_ controller: SearchResultsController, didSelect item: Item) {}
}

class SearchResultsController: UIViewController {

    // Section
    typealias Section = SearchResultsViewModel.Section
    typealias Row = SearchResultsViewModel.Row
    
    // View Model
    private var viewModel: SearchResultsViewModel!

    // Collection View
    private var collectionView: UICollectionView! = nil
    var dataSource: UICollectionViewDiffableDataSource<Section, Row>! = nil

    // For Combine
    private var cancellables: Set<AnyCancellable> = []
    
    // Delegate
    var delegate: SearchResultsControllerDelegate? = nil
    
    // Outlet
    @IBOutlet weak var listView: UIView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var zeroItemMessage: UILabel!
    
    // Property
    var initialItemType: ItemType = .keywords
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Instantiate view model with initial type
        viewModel = SearchResultsViewModel(initialItemType: initialItemType)

        // Set delegate to myself if it's nil
        if delegate == nil {
            delegate = self
        }
        
        // Collection View
        configureHierarchy()
        configureDataSource()
        
        // Subscribe rows
        viewModel.$rows
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rows in
                // Update data source
                var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
                snapshot.appendSections([.searchHistory])
                snapshot.appendItems(rows)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
                // Hide list view (show message view)
                self?.listView.isHidden = rows.count == 0
            }
            .store(in: &cancellables)
        
        viewModel.$itemType
            .receive(on: DispatchQueue.main)
            .map {
                switch $0 {
                case .bookmark:
                    return NSLocalizedString(
                        "No bookmark",
                        comment: "Zero state of bookmark"
                    )
                case .history:
                    return NSLocalizedString(
                        "No visit history",
                        comment: "Zero state of visit history"
                    )
                case .keywords:
                    return NSLocalizedString(
                        "No search keywords history",
                        comment: "Zero state of keywords history"
                    )
                case .tab:
                    return ""
                }
            }
            .sink { [weak self] in
                self?.zeroItemMessage.text = $0
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Collection View
extension SearchResultsController {
    private func createLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        // Swipe Actions
        config.trailingSwipeActionsConfigurationProvider = { indexPath in
            let deleteAction = UIContextualAction(
                style: .destructive,
                title: NSLocalizedString("Delete", comment: "in swipe menu of search results")
            ) { (action, view, completion) in
                self.viewModel.delete(indexPath: indexPath)
                // To fix animation of removing the cell
                DispatchQueue.main.async {
                    completion(true)
                }
            }
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: listView.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        listView.addSubview(collectionView)
    }
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row> { (cell, indexPath, row) in
            // Content
            var content = cell.defaultContentConfiguration()
            content.text = row.text
            content.textProperties.numberOfLines = 1
            content.textProperties.lineBreakMode = .byTruncatingTail
            if let image = row.image {
                content.image = image
            }
            if let secondaryText = row.secondaryText {
                content.secondaryText = secondaryText
                content.secondaryTextProperties.numberOfLines = 1
                content.secondaryTextProperties.lineBreakMode = .byTruncatingTail
            }
            cell.contentConfiguration = content
            // Accessaries
            cell.accessories = []
        }
        dataSource = UICollectionViewDiffableDataSource<Section, Row>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Row) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
    }
}

// MARK: - Collection View Delegate

extension SearchResultsController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Call delegate method
        if let item = viewModel.rows[indexPath.row].item {
            delegate?.searchResultsController(self, didSelect: item)
        }
        // Deselect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
}

// MARK: - Search Result Collection Delegate

extension SearchResultsController: SearchResultsControllerDelegate {
    func searchResultsController(_ controller: SearchResultsController, didSelect item: Item) {
        // Set keywords
        viewModel.setKeywords(item.keywords)
    }
}

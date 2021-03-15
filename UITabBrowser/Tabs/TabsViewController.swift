//
//  TabsViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/01/22.
//
//  The original code is in the project "ImplementingModernCollectionViews"

import Combine
import UIKit

let RADIUS: CGFloat = 6.0

class TabsViewController: UIViewController {
    typealias Section = TabsViewModel.Section

    private let viewModel = TabsViewModel()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Tab>!

    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // initializing
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()

        // subscribe tabs
        viewModel.$tabs
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { tabs in
                // update tabs
                var recentsSnapshot = NSDiffableDataSourceSectionSnapshot<Tab>()
                recentsSnapshot.append(tabs)
                self.dataSource.apply(recentsSnapshot, to: .tabs, animatingDifferences: true)
            }
            .store(in: &cancellables)

        // subscribe selected to scroll to the selected tab
        viewModel.$selectedIndex
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { selected in
                // scroll tabs to show selected
                // (use async to wait for appending new tab)
                DispatchQueue.main.async {
                    self.collectionView.scrollToItem(
                        at: IndexPath(row: selected, section: 0),
                        at: .centeredHorizontally,
                        animated: true
                    )
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        view.subviews.forEach { $0.removeFromSuperview() }
        cancellables.forEach { $0.cancel() }
    }
}

extension TabsViewController {

    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.scrollsToTop = false
        view.addSubview(collectionView)
    }

    func createLayout() -> UICollectionViewLayout {

        let sectionProvider = {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment)
                -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(
                top: -1.0 * RADIUS,
                leading: 2.0,
                bottom: 1.0,
                trailing: 2.0
            )
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.3),
                heightDimension: .fractionalHeight(1.0)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0.0,
                leading: 3.0,
                bottom: 2.0,
                trailing: 3.0
            )
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.collectionView.selectItem(
                            at: indexPath,
                            animated: false,
                            scrollPosition: []
                        )
                    }
                }
            } else {
                self.collectionView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }

    func configuredGridCell() -> UICollectionView.CellRegistration<TabCell, Tab> {
        return UICollectionView.CellRegistration<TabCell, Tab> { (cell, indexPath, tab) in
            cell.titleLabel.text =
                tab.title.isEmpty
                ? NSLocalizedString("Loading...", comment: "in Tab")
                : tab.title
            cell.imageView.image = tab.pinned ? UIImage(systemName: "pin.fill") : tab.favicon
            cell.imageView.isHidden = tab.loading
            cell.isActivityAnimating = tab.loading
            cell.isSelected = tab.active

            // Background
            var background = UIBackgroundConfiguration.listPlainCell()
            background.cornerRadius = RADIUS
            background.strokeColor = .systemGray3
            background.strokeWidth = 1.0 / cell.traitCollection.displayScale
            background.backgroundColor =
                tab.active
                ? UIColor.systemBackground
                : UIColor.systemGray5
            cell.backgroundConfiguration = background
        }
    }

    func configureDataSource() {
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, Tab>(
            collectionView: collectionView
        ) {
            (collectionView, indexPath, tab) -> TabCell? in
            return collectionView.dequeueConfiguredReusableCell(
                using: self.configuredGridCell(),
                for: indexPath,
                item: tab
            )
        }
    }

    func applyInitialSnapshots() {
        // apply sections
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tab>()
        snapshot.appendSections(Section.allCases)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension TabsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Tap on the tab
        if viewModel.selectedIndex == indexPath.row {
            // Scroll to top
            Browsers.shared.currentBrowser?.scrollToTop()
        } else {
            // Select tab
            viewModel.select(index: indexPath.row)
        }
        // deselect
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - Context Menu

extension TabsViewController {
    private func showActivity(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }
    private func openDefaultBrowser(url: URL) {
        UIApplication.shared.open(url, options: [:])
    }
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let tab = self.viewModel.tabs[indexPath.row]
        let actionProvider: ([UIMenuElement]) -> UIMenu? = { _ in
            // Close
            let closeAction = UIAction(
                title: NSLocalizedString("Close", comment: "in Tab's context menu"),
                image: UIImage(systemName: "clear"),
                attributes: tab.pinned ? [.destructive, .disabled] : [.destructive]
            ) { _ in
                self.viewModel.delete(id: tab.id)
            }
            // Reload
            let reloadAction = UIAction(
                title: NSLocalizedString("Reload", comment: "in Tab's context menu"),
                image: UIImage(systemName: "arrow.counterclockwise"),
                attributes: []
            ) { _ in
                self.viewModel.reload(id: tab.id)
            }
            // Bookmark
            let bookmarkAction = UIAction(
                title: NSLocalizedString("Add to Bookmark", comment: "in Tab's context menu"),
                image: UIImage(systemName: "bookmark"),
                attributes: []
            ) { _ in
                if let url = tab.url {
                    self.viewModel.bookmark(
                        url: url,
                        title: tab.title,
                        browserId: tab.id
                    )
                }
            }
            // Share
            let shareAction = UIAction(
                title: NSLocalizedString("Share...", comment: "in Tab's context menu"),
                image: UIImage(systemName: "square.and.arrow.up"),
                attributes: []
            ) { _ in
                if let url = tab.url {
                    self.showActivity(url: url)
                }
            }
            // Open new tab
            let openNewTabAction = UIAction(
                title: NSLocalizedString("Open New Tab", comment: "in Tab's context menu"),
                image: UIImage(systemName: "plus.rectangle.on.rectangle"),
                attributes: []
            ) { _ in
                if let url = tab.url {
                    self.viewModel.openNewTab(url: url)
                }
            }
            // Open in default browser
            let openDefaultBrowserAction = UIAction(
                title: NSLocalizedString(
                    "Open in Default Browser",
                    comment: "in Tab's context menu"
                ),
                image: UIImage(systemName: "arrow.up.forward.app"),
                attributes: []
            ) { _ in
                if let url = tab.url {
                    self.openDefaultBrowser(url: url)
                }
            }
            // Pin/Unpin
            let pinAction = UIAction(
                title: NSLocalizedString("Pin", comment: "in Tab's context menu"),
                image: UIImage(systemName: "pin"),
                attributes: []
            ) { _ in
                self.viewModel.setPin(id: tab.id, pinned: true)
            }
            let unpinAction = UIAction(
                title: NSLocalizedString("Unpin", comment: "in Tab's context menu"),
                image: UIImage(systemName: "pin.slash"),
                attributes: []
            ) { _ in
                self.viewModel.setPin(id: tab.id, pinned: false)
            }
            // Define menu items
            let children =
                tab.type == .browser
                ? [
                    closeAction,
                    shareAction,
                    openDefaultBrowserAction,
                    openNewTabAction,
                    tab.pinned ? unpinAction : pinAction,
                    reloadAction,
                    bookmarkAction,
                ]
                : [closeAction]
            // Show menu
            return UIMenu(
                title: tab.title,
                image: nil,
                identifier: nil,
                children: children
            )
        }
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: actionProvider
        )
    }
}

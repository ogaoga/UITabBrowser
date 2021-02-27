//
//  SearchResultsViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/06.
//

import UIKit
import Combine

let SetTextInSearchBarNotification = Notification.Name(rawValue: "FillSearchBar")

class SearchResultsViewModel: ObservableObject {
    
    @Published var rows: [Row] = [];
    @Published var itemType: ItemType = .keywords
    
    private let sharedItems = Items.shared

    enum Section: Int, CaseIterable {
        case searchHistory
        
        func title() -> String {
            switch self {
            case .searchHistory:
                return NSLocalizedString(
                    "Search History",
                    comment: "Section title in search results"
                )
            }
        }
    }
    
    struct Row: Hashable {
        let id: ItemID
        let item: Item?
        let text: String
        let secondaryText: String?
        let image: UIImage?
        
        init(item: Item) {
            self.item = item
            self.id = item.id
            switch item.type {
            case .history:
                self.text = item.title
                self.secondaryText = item.url.absoluteString
                self.image = UIImage(systemName: "clock")
            case .bookmark:
                self.text = item.title
                self.secondaryText = item.url.absoluteString
                self.image = UIImage(systemName: "bookmark.fill")
            case .keywords:
                self.text = item.keywords
                self.secondaryText = nil
                self.image = UIImage(systemName: "magnifyingglass")
            case .tab:
                self.text = item.title
                self.secondaryText = item.url.absoluteString
                self.image = UIImage(systemName: "t.square")
            }
        }
    }
    
    init(initialItemType: ItemType = .keywords) {
        // Set initial item type
        sharedItems.setType(initialItemType)

        // Subscribe items
        sharedItems.$items
            .map { items in
                return items.map { Row(item: $0) }
            }
            .assign(to: &$rows)
        
        // Subscribe item type to switch zero item message
        sharedItems.$itemType
            .assign(to: &$itemType)
    }
    
    func setKeywords(_ keywords: String) {
        NotificationCenter.default.post(
            name: SetTextInSearchBarNotification,
            object: keywords + " "
        )
    }
    
    func delete(indexPath: IndexPath) {
        let row = rows[indexPath.row]
        if let itemId = row.item?.id {
            Items.shared.delete(id: itemId)
        }
    }
}

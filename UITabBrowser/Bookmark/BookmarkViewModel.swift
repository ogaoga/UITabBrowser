//
//  BookmarkViewModel.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/11.
//

import UIKit
import Combine

class BookmarkViewModel: ObservableObject {

    // MARK: - Enumerated type
    
    enum Scope: Int, CaseIterable {
        case bookmark = 0
        case history = 1
        case search = 2

        var title: String {
            switch self {
            case .bookmark:
                return NSLocalizedString("Bookmark", comment: "Scope title in bookmark view")
            case .history:
                return NSLocalizedString("History", comment: "Scope title in bookmark view")
            case .search:
                return NSLocalizedString("Search History", comment: "Scope title in bookmark view")
            }
        }
        
        static var titles: [String] {
            return allCases.map { $0.title }
        }
        
        var itemType: ItemType {
            switch self {
            case .bookmark:
                return .bookmark
            case .history:
                return .history
            case .search:
                return .keywords
            }
        }
    }
    
    // MARK: - Private properties
    
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Published properties
    
    @Published var scope: Scope = .bookmark
    @Published var enteredText = ""
    @Published var isDeleteAllButtonEnabled = true

    // MARK: - Initializer & deinitializer
    
    init() {
        // DeleteAll button
        $scope
            .combineLatest(Items.shared.$items)
            .map { (scope, _) in
                // TODO: fix this workaround
                let items = Items.shared.getItems(type: scope.itemType, filterText: self.enteredText)
                return (scope == .history || scope == .search) && items.count > 0
            }
            .assign(to: &$isDeleteAllButtonEnabled)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Commands
    
    func setScope(scope: Scope) {
        self.scope = scope
    }
    
    func setEnteredText(_ text: String) {
        self.enteredText = text
    }
    
    func deleteAll(scope: Scope) {
        let items = Items.shared
        switch scope {
        case .history, .search:
            items.deleteAll(itemType: scope.itemType)
        default:
            break
        }
    }
}

//
//  Items.swift
//  repeatitive
//
//  Created by ogaoga on 2020/12/31.
//

import CoreData
import Combine
import UIKit

typealias ItemID = UUID

enum ItemType: String {
    case history
    case bookmark
    case keywords
    case tab
}

struct Item: Hashable {
    var id: ItemID
    var type: ItemType
    var created: Date
    var title: String
    var url: URL
    var keywords: String
    var browserId: BrowserID
    var pinned: Bool
    var selected: Bool
    var order: Int?
}

final class Items: ObservableObject {
    // Singleton
    static let shared = Items()
    
    let entityName = "ItemEntity"
    
    // MARK: - Private properties

    private var viewContext: NSManagedObjectContext! = nil
    @Published var filterText: String = ""
    @Published var itemType: ItemType = .bookmark

    // MARK: - Published properties

    @Published var items: [Item] = []

    // MARK: - Commands
    
    func setType(_ type: ItemType) {
        self.itemType = type
    }
    
    func setFilterText(_ text: String) {
        self.filterText = text
    }

    // MARK: - Initializer & Deinitializer
    
    init() {
        // Initialize Core Data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        
        // Subscribe
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didChangeObjectsNotification, object: viewContext)
            .compactMap { $0.object as? NSManagedObjectContext }
            .compactMap { context in
                return self.getItems(type: self.itemType, filterText: self.filterText)
            }
            .assign(to: &$items)

        // Update items when type or filter text is changed
        $itemType.combineLatest($filterText)
            .dropFirst()
            .compactMap { (type, filterText) in
                return self.getItems(type: type, filterText: filterText)
            }
            .assign(to: &$items)
    }
        
    // MARK: - Core Data

    // get items from Core Data
    func getItems(type: ItemType, filterText: String) -> [Item] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.resultType = .managedObjectResultType
        // TODO: Distinct
        fetchRequest.returnsDistinctResults = true
        fetchRequest.propertiesToFetch = ["title"]
        // Sort
        let sortDescripter = type == .tab
            ? NSSortDescriptor(key: "order", ascending: true)
            : NSSortDescriptor(key: "created", ascending: false)
        fetchRequest.sortDescriptors = [sortDescripter]
        // Type
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        // Filter text
        if !filterText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", filterText))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            let itemEntities = try viewContext.fetch(fetchRequest) as! [ItemEntity]
            return itemEntities.map {
                return Item(
                    id: $0.id ?? UUID(),
                    type: ItemType(rawValue: $0.type!)!,
                    created: $0.created ?? Date(),
                    title: $0.title ?? "",
                    url: $0.url!,
                    keywords: $0.keywords ?? "",
                    browserId: $0.browserId!,
                    pinned: $0.pinned,
                    selected: $0.selected,
                    order: Int($0.order)
                )
            }
        } catch let error as NSError {
            print(error)
            return []
        }
    }
    
    private func getEntity<T: NSManagedObject>(of id: ItemID, entityName: String) -> T? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let entities = try viewContext.fetch(fetchRequest) as! [T]
            if entities.count > 0 {
                return entities[0]
            } else {
                return nil
            }
        } catch let error {
            print(error)
            return nil
        }
    }
    
    func add(
        type: ItemType,
        title: String,
        url: URL,
        keywords: String,
        browserId: BrowserID,
        selected: Bool = false,
        pinned: Bool = false,
        order: Int? = nil
    ) {
        // Triming
        let keywords = keywords.trimmingCharacters(in: .whitespacesAndNewlines)
        // find same record
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.resultType = .managedObjectResultType
        switch type {
        case .keywords:
            // Same keywords will be overwritten with new one
            fetchRequest.predicate = NSPredicate(
                format: "keywords == %@ AND type == %@",
                keywords, type.rawValue
            )
        default:
            // Same URL record will be overwritten with new one
            fetchRequest.predicate = NSPredicate(
                format: "url == %@ AND type == %@",
                url.absoluteString, type.rawValue
            )
        }
        do {
            // Fetch
            let entities = try viewContext.fetch(fetchRequest) as! [ItemEntity]
            if entities.count > 0 {
                // Update existing record (overwrite)
                let entity = entities[0]
                entity.created = Date()
                entity.title = title
                entity.keywords = keywords
                entity.browserId = browserId
            } else {
                // Add a new record
                let entity = NSEntityDescription.entity(forEntityName: entityName,
                                                        in: viewContext)!
                let item = NSManagedObject(entity: entity,
                                           insertInto: viewContext)
                // set
                item.setValuesForKeys([
                    "created": Date(),
                    "id": UUID(), // ItemID
                    "keywords": keywords,
                    "title": title,
                    "type": type.rawValue,
                    "url": url,
                    "browserId": browserId,
                    "selected": selected,
                    "pinned": pinned,
                    "order": order ?? 0
                ])
            }
            // Save
            try viewContext.save()
        } catch let error as NSError {
            // TODO: Error handling
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func delete(id: ItemID) {
        if let itemEntity = getEntity(of: id, entityName: entityName) {
            viewContext.delete(itemEntity)
            do {
                try viewContext.save()
            } catch let error {
                print(error)
            }
        } else {
            print("Couldn't get itemEntity of \(id)")
        }
    }
    
    func deleteAll(itemType: ItemType? = nil) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.resultType = .managedObjectResultType
        // Set type
        if let type = itemType {
            fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue)
        }
        do {
            // Fetch
            let entities = try viewContext.fetch(fetchRequest) as! [ItemEntity]
            // Delete
            entities.forEach { entity in
                viewContext.delete(entity)
            }
            // Save
            try viewContext.save()
        } catch let error as NSError {
            // TODO: Error handling
            print(error)
        }
    }
    
    func item(of id: ItemID) -> Item? {
        // TODO: search from CoreData instead of items
        return items.find(where: { $0.id == id })
    }
}

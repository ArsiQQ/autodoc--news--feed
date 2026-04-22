import CoreData
import os.log

final class NewsCacheService: NewsCacheServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let stack: CoreDataStack
    private let ttl: TimeInterval
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "NewsCacheService")

    // MARK: - Init

    init(stack: CoreDataStack, ttl: TimeInterval = 3600) {
        self.stack = stack
        self.ttl = ttl
    }

    // MARK: - NewsCacheServiceProtocol

    func cachedNews(page: Int, pageSize: Int) async -> [NewsItem] {
        guard stack.isStoreLoaded else { return [] }
        let context = stack.newBackgroundContext()
        return await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "NewsItemEntity")
            let minDate = Date().addingTimeInterval(-self.ttl)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "page == %d", Int16(page)),
                NSPredicate(format: "cachedAt >= %@", minDate as NSDate)
            ])
            request.sortDescriptors = [NSSortDescriptor(key: "publishedDate", ascending: false)]

            do {
                let results = try context.fetch(request)
                return results.compactMap { NewsItem(managedObject: $0) }
            } catch {
                self.logger.error("Ошибка чтения кэша: \(error.localizedDescription)")
                return []
            }
        }
    }

    func save(news: [NewsItem], page: Int) async {
        guard !news.isEmpty, stack.isStoreLoaded else { return }
        let context = stack.newBackgroundContext()
        await context.perform {
            for item in news {
                let request = NSFetchRequest<NSManagedObject>(entityName: "NewsItemEntity")
                request.predicate = NSPredicate(format: "id == %lld", Int64(item.id))
                request.fetchLimit = 1

                do {
                    let existing = try context.fetch(request).first
                    let entity = existing ?? NSEntityDescription.insertNewObject(
                        forEntityName: "NewsItemEntity",
                        into: context
                    )
                    entity.populate(from: item, page: page)
                } catch {
                    self.logger.error("Ошибка upsert для id \(item.id): \(error.localizedDescription)")
                }
            }

            self.deleteExpired(in: context)

            do {
                try context.save()
            } catch {
                self.logger.error("Ошибка сохранения контекста: \(error.localizedDescription)")
            }
        }
    }

    func clearAll() async {
        guard stack.isStoreLoaded else { return }
        let context = stack.newBackgroundContext()
        await context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsItemEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [self.stack.viewContext]
                    )
                }
            } catch {
                self.logger.error("Ошибка очистки кэша: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func deleteExpired(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NewsItemEntity")
        let expirationDate = Date().addingTimeInterval(-ttl)
        request.predicate = NSPredicate(format: "cachedAt < %@", expirationDate as NSDate)

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            _ = try context.execute(deleteRequest)
        } catch {
            logger.error("Ошибка удаления просроченных записей: \(error.localizedDescription)")
        }
    }
}

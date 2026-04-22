import CoreData

final class CoreDataStack: @unchecked Sendable {

    // MARK: - Properties

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private(set) var isStoreLoaded = false

    // MARK: - Init

    init(modelName: String = "AutodocFeed") {
        let model = Self.createModel()
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        container.loadPersistentStores { [weak self] _, error in
            if let error {
                print("[CoreDataStack] Ошибка загрузки хранилища: \(error.localizedDescription)")
                return
            }
            self?.isStoreLoaded = true
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Public

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Private

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "NewsItemEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .integer64AttributeType

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType

        let descriptionTextAttr = NSAttributeDescription()
        descriptionTextAttr.name = "descriptionText"
        descriptionTextAttr.attributeType = .stringAttributeType

        let publishedDateAttr = NSAttributeDescription()
        publishedDateAttr.name = "publishedDate"
        publishedDateAttr.attributeType = .dateAttributeType

        let urlStringAttr = NSAttributeDescription()
        urlStringAttr.name = "urlString"
        urlStringAttr.attributeType = .stringAttributeType

        let fullUrlStringAttr = NSAttributeDescription()
        fullUrlStringAttr.name = "fullUrlString"
        fullUrlStringAttr.attributeType = .stringAttributeType

        let titleImageUrlStringAttr = NSAttributeDescription()
        titleImageUrlStringAttr.name = "titleImageUrlString"
        titleImageUrlStringAttr.attributeType = .stringAttributeType
        titleImageUrlStringAttr.isOptional = true

        let categoryTypeAttr = NSAttributeDescription()
        categoryTypeAttr.name = "categoryType"
        categoryTypeAttr.attributeType = .stringAttributeType

        let pageAttr = NSAttributeDescription()
        pageAttr.name = "page"
        pageAttr.attributeType = .integer16AttributeType

        let cachedAtAttr = NSAttributeDescription()
        cachedAtAttr.name = "cachedAt"
        cachedAtAttr.attributeType = .dateAttributeType

        entity.properties = [
            idAttr, titleAttr, descriptionTextAttr, publishedDateAttr,
            urlStringAttr, fullUrlStringAttr, titleImageUrlStringAttr,
            categoryTypeAttr, pageAttr, cachedAtAttr
        ]

        let uniqueConstraint = [["id"]]
        entity.uniquenessConstraints = uniqueConstraint

        model.entities = [entity]
        return model
    }
}

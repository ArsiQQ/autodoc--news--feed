import CoreData

extension NSManagedObject {

    func populate(from item: NewsItem, page: Int) {
        setValue(Int64(item.id), forKey: "id")
        setValue(item.title, forKey: "title")
        setValue(item.description, forKey: "descriptionText")
        setValue(item.publishedDate, forKey: "publishedDate")
        setValue(item.url, forKey: "urlString")
        setValue(item.fullUrl.absoluteString, forKey: "fullUrlString")
        setValue(item.titleImageUrl?.absoluteString, forKey: "titleImageUrlString")
        setValue(item.categoryType, forKey: "categoryType")
        setValue(Int16(page), forKey: "page")
        setValue(Date(), forKey: "cachedAt")
    }
}

extension NewsItem {

    init?(managedObject: NSManagedObject) {
        guard
            let title = managedObject.value(forKey: "title") as? String,
            let descriptionText = managedObject.value(forKey: "descriptionText") as? String,
            let publishedDate = managedObject.value(forKey: "publishedDate") as? Date,
            let urlString = managedObject.value(forKey: "urlString") as? String,
            let fullUrlString = managedObject.value(forKey: "fullUrlString") as? String,
            let fullUrl = URL(string: fullUrlString),
            let categoryType = managedObject.value(forKey: "categoryType") as? String
        else {
            return nil
        }

        let id = managedObject.value(forKey: "id") as? Int64 ?? 0
        let titleImageUrlString = managedObject.value(forKey: "titleImageUrlString") as? String
        let titleImageUrl = titleImageUrlString.flatMap { URL(string: $0) }

        self.init(
            id: Int(id),
            title: title,
            description: descriptionText,
            publishedDate: publishedDate,
            url: urlString,
            fullUrl: fullUrl,
            titleImageUrl: titleImageUrl,
            categoryType: categoryType
        )
    }
}

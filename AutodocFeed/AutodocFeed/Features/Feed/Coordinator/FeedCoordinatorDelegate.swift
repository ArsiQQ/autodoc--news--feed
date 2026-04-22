import Foundation

@MainActor
protocol FeedCoordinatorDelegate: AnyObject {
    func feedViewController(_ controller: FeedViewController, didSelect item: NewsItem)
}

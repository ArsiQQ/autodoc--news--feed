import UIKit

@MainActor
final class FeedCoordinator: FeedCoordinatorDelegate {

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let newsService: NewsServiceProtocol
    private let imageLoader: ImageLoaderProtocol

    // MARK: - Init

    init(navigationController: UINavigationController,
         newsService: NewsServiceProtocol,
         imageLoader: ImageLoaderProtocol) {
        self.navigationController = navigationController
        self.newsService = newsService
        self.imageLoader = imageLoader
    }

    // MARK: - Start

    func start() {
        let viewModel = FeedViewModel(service: newsService)
        let feedVC = FeedViewController(viewModel: viewModel, imageLoader: imageLoader)
        feedVC.coordinatorDelegate = self
        navigationController.pushViewController(feedVC, animated: false)
    }

    // MARK: - FeedCoordinatorDelegate

    func feedViewController(_ controller: FeedViewController, didSelect item: NewsItem) {
        let detailVC = NewsDetailViewController(item: item, imageLoader: imageLoader)
        navigationController.pushViewController(detailVC, animated: true)
    }
}

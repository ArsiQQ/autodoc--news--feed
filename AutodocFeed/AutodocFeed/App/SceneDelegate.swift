import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: FeedCoordinator?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let apiClient = APIClient(baseURL: URL(string: "https://webapi.autodoc.ru")!)

        let coreDataStack = CoreDataStack()
        let newsCacheService = NewsCacheService(stack: coreDataStack)
        let networkNewsService = NewsService(client: apiClient)
        let newsService = CachingNewsService(
            networkService: networkNewsService,
            cacheService: newsCacheService
        )

        let diskImageCache = DiskImageCache()
        let imageLoader = ImageLoader(diskCache: diskImageCache)

        let navigationController = UINavigationController()
        let coordinator = FeedCoordinator(
            navigationController: navigationController,
            newsService: newsService,
            imageLoader: imageLoader
        )
        coordinator.start()
        self.coordinator = coordinator

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

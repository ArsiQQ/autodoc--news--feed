import Foundation
import Combine

@MainActor
final class FeedViewModel {

    // MARK: - Types

    enum State {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum Event {
        case reloaded([NewsItem])
        case appended([NewsItem])
        case stateChanged(State)
    }

    // MARK: - Properties

    private(set) var items: [NewsItem] = []
    private(set) var state: State = .idle

    private let service: NewsServiceProtocol
    private let pageSize: Int
    private var currentPage = 0
    private var totalCount: Int?
    private var loadTask: Task<Void, Never>?

    private let eventSubject = PassthroughSubject<Event, Never>()
    var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    var hasMore: Bool {
        guard let totalCount else { return true }
        return items.count < totalCount
    }

    // MARK: - Init

    init(service: NewsServiceProtocol, pageSize: Int = 5) {
        self.service = service
        self.pageSize = pageSize
    }

    // MARK: - Actions

    func loadNextPageIfNeeded() {
        if case .loading = state { return }
        guard hasMore else { return }

        let nextPage = currentPage + 1
        state = .loading
        eventSubject.send(.stateChanged(.loading))

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchNews(page: nextPage,
                                                                pageSize: self.pageSize)
                if Task.isCancelled { return }
                let existingIDs = Set(self.items.map(\.id))
                let newOnes = response.news.filter { !existingIDs.contains($0.id) }
                self.items.append(contentsOf: newOnes)
                if response.totalCount > 0 {
                    self.totalCount = response.totalCount
                }
                self.currentPage = nextPage
                self.state = .loaded
                self.eventSubject.send(.appended(newOnes))
                self.eventSubject.send(.stateChanged(.loaded))
            } catch is CancellationError {

            } catch {
                self.state = .failed(error.localizedDescription)
                self.eventSubject.send(.stateChanged(self.state))
            }
        }
    }

    func reload() {
        loadTask?.cancel()
        currentPage = 0
        totalCount = nil
        items = []
        state = .idle
        eventSubject.send(.reloaded([]))
        loadNextPageIfNeeded()
    }
}

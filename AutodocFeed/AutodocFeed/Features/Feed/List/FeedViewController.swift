import UIKit
import Combine

nonisolated private enum FeedSection: Hashable, Sendable { case main }

final class FeedViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: FeedViewModel
    private let imageLoader: ImageLoaderProtocol
    weak var coordinatorDelegate: FeedCoordinatorDelegate?
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<FeedSection, NewsItem>!
    private var prefetchTasks: [IndexPath: Task<Void, Never>] = [:]

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: FeedLayoutFactory.makeLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.delegate = self
        view.prefetchDataSource = self
        view.alwaysBounceVertical = true
        return view
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return control
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Init

    init(viewModel: FeedViewModel, imageLoader: ImageLoaderProtocol) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        layout()
        configureDataSource()
        bind()
        viewModel.loadNextPageIfNeeded()
    }

    // MARK: - Setup

    private func setup() {
        title = "Новости"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        collectionView.refreshControl = refreshControl
        view.addSubview(collectionView)
        view.addSubview(errorLabel)
    }

    private func layout() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<NewsCell, NewsItem> { [weak self] cell, indexPath, item in
            guard let self else { return }
            let targetSize = self.estimatedImageSize()
            cell.configure(with: item, imageTargetSize: targetSize, imageLoader: self.imageLoader)
        }

        let footerRegistration = UICollectionView.SupplementaryRegistration<LoadingFooterView>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] footer, _, _ in
            guard let self else { return }
            if case .loading = self.viewModel.state {
                footer.setAnimating(true)
            } else {
                footer.setAnimating(false)
            }
        }

        dataSource = UICollectionViewDiffableDataSource<FeedSection, NewsItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                         for: indexPath,
                                                         item: item)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration,
                                                                  for: indexPath)
        }

        var initial = NSDiffableDataSourceSnapshot<FeedSection, NewsItem>()
        initial.appendSections([.main])
        dataSource.apply(initial, animatingDifferences: false)
    }

    // MARK: - Bindings

    private func bind() {
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)
    }

    private func handle(_ event: FeedViewModel.Event) {
        switch event {
        case .reloaded(let items):
            applyFull(items)
        case .appended(let newItems):
            appendItems(newItems)
        case .stateChanged(let state):
            render(state: state)
        }
    }

    // MARK: - Snapshot Updates

    private func applyFull(_ items: [NewsItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<FeedSection, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
        errorLabel.isHidden = !items.isEmpty ? true : errorLabel.isHidden
    }

    private func appendItems(_ newItems: [NewsItem]) {
        guard !newItems.isEmpty else { return }
        var snapshot = dataSource.snapshot()
        snapshot.appendItems(newItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
        errorLabel.isHidden = true
    }

    private func render(state: FeedViewModel.State) {
        switch state {
        case .idle, .loading:
            errorLabel.isHidden = true
        case .loaded:
            errorLabel.isHidden = true
            refreshControl.endRefreshing()
        case .failed(let message):
            refreshControl.endRefreshing()
            if viewModel.items.isEmpty {
                errorLabel.text = message
                errorLabel.isHidden = false
            }
        }
        updateFooterIfNeeded()
    }

    private func updateFooterIfNeeded() {
        let visibleFooters = collectionView.visibleSupplementaryViews(
            ofKind: UICollectionView.elementKindSectionFooter
        )
        for case let footer as LoadingFooterView in visibleFooters {
            if case .loading = viewModel.state {
                footer.setAnimating(true)
            } else {
                footer.setAnimating(false)
            }
        }
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.reload()
    }

    // MARK: - Helpers

    private func estimatedImageSize() -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: width * 9.0 / 16.0)
    }
}

// MARK: - UICollectionViewDelegate

extension FeedViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let threshold = viewModel.items.count - 3
        if indexPath.item >= threshold {
            viewModel.loadNextPageIfNeeded()
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinatorDelegate?.feedViewController(self, didSelect: item)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension FeedViewController: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView,
                        prefetchItemsAt indexPaths: [IndexPath]) {
        let targetSize = estimatedImageSize()
        let scale = UIScreen.main.scale

        for indexPath in indexPaths {
            guard let item = dataSource.itemIdentifier(for: indexPath),
                  let url = item.titleImageUrl else { continue }

            prefetchTasks[indexPath] = Task { [weak self] in
                guard let self else { return }
                _ = try? await self.imageLoader.image(for: url,
                                                      targetSize: targetSize,
                                                      scale: scale)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            prefetchTasks[indexPath]?.cancel()
            prefetchTasks[indexPath] = nil
        }
    }
}

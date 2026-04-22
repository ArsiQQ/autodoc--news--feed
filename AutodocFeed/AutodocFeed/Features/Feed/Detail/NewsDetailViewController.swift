import UIKit

final class NewsDetailViewController: UIViewController {

    // MARK: - Properties

    private let item: NewsItem
    private let imageLoader: ImageLoaderProtocol

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - UI Elements

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alwaysBounceVertical = true
        return view
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)
        return stack
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 14
        return view
    }()

    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .tintColor
        label.numberOfLines = 1
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private var imageLoadTask: Task<Void, Never>?

    // MARK: - Init

    init(item: NewsItem, imageLoader: ImageLoaderProtocol) {
        self.item = item
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        layout()
        populate()
    }

    deinit {
        imageLoadTask?.cancel()
    }

    // MARK: - Setup

    private func setup() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        title = item.categoryType

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(categoryLabel)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(dateLabel)
        contentStack.addArrangedSubview(descriptionLabel)

        contentStack.setCustomSpacing(20, after: imageView)
        contentStack.setCustomSpacing(6, after: categoryLabel)
        contentStack.setCustomSpacing(8, after: titleLabel)
        contentStack.setCustomSpacing(20, after: dateLabel)
    }

    private func layout() {
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),

            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor,
                                              multiplier: 9.0 / 16.0)
        ])
    }

    private func populate() {
        categoryLabel.text = item.categoryType.uppercased()
        titleLabel.text = item.title
        dateLabel.text = Self.dateFormatter.string(from: item.publishedDate)
        descriptionLabel.text = item.description

        if let url = item.titleImageUrl {
            imageView.isHidden = false
            loadImage(from: url)
        } else {
            imageView.isHidden = true
        }
    }

    private func loadImage(from url: URL) {
        imageLoadTask?.cancel()
        imageLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let scale = UIScreen.main.scale
                let width = UIScreen.main.bounds.width
                let targetSize = CGSize(width: width, height: width * 9.0 / 16.0)
                let loaded = try await imageLoader.image(for: url,
                                                         targetSize: targetSize,
                                                         scale: scale)
                guard !Task.isCancelled else { return }
                imageView.image = loaded
            } catch {

            }
        }
    }
}

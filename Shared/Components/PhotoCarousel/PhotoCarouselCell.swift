import UIKit

final class PhotoCarouselCell: UICollectionViewCell {
    static let loadingPlaceholderImage = UIImage(systemName: "photo")
    static let failureImage = UIImage(systemName: "exclamationmark.triangle")

    private let imageView = UIImageView()
    private var imageLoadTask: Task<Void, Never>?
    private var configurationToken: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureImageView()
    }

    deinit {
        imageLoadTask?.cancel()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageLoad()
        imageView.image = nil
    }

    func configure(with item: PhotoCarouselItem, imageLoader: ImageLoading) {
        cancelImageLoad()

        switch item {
        case .image(let image):
            showLoadedImage(image)
        case .url(let url):
            showLoadingPlaceholder()

            let token = UUID()
            configurationToken = token
            imageLoadTask = Task { @MainActor [weak self] in
                do {
                    let image = try await imageLoader.image(for: url)
                    guard !Task.isCancelled, self?.configurationToken == token else { return }
                    self?.showLoadedImage(image)
                    self?.imageLoadTask = nil
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled, self?.configurationToken == token else { return }
                    self?.showFailureImage()
                    self?.imageLoadTask = nil
                }
            }
        }
    }

    func cancelImageLoad() {
        imageLoadTask?.cancel()
        imageLoadTask = nil
        configurationToken = nil
    }

    private func configureImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func showLoadingPlaceholder() {
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.image = Self.loadingPlaceholderImage
    }

    private func showLoadedImage(_ image: UIImage) {
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
    }

    private func showFailureImage() {
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.image = Self.failureImage
    }
}

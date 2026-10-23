import UIKit

final class MaintenanceRequestViewController: UIViewController {
    private let request: MaintenanceRequest
    private let carouselView = PhotoCarouselView()

    init(request: MaintenanceRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(request:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Maintenance Request"
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "maintenanceRequestScreen"

        configureHierarchy()
        configureContent()
    }

    private func configureHierarchy() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        let stackView = UIStackView()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        carouselView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 12

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        let titleLabel = makeLabel(
            style: .title1,
            weight: .bold,
            accessibilityIdentifier: "maintenanceRequestTitle"
        )
        let statusLabel = makeLabel(
            style: .headline,
            weight: .semibold,
            color: .systemBlue,
            accessibilityIdentifier: "maintenanceRequestStatus"
        )
        let locationLabel = makeLabel(
            style: .body,
            accessibilityIdentifier: "maintenanceRequestLocation"
        )
        let submittedDateLabel = makeLabel(
            style: .subheadline,
            color: .secondaryLabel,
            accessibilityIdentifier: "maintenanceRequestSubmittedDate"
        )
        let detailsHeadingLabel = makeLabel(style: .headline, weight: .semibold)
        let detailsLabel = makeLabel(
            style: .body,
            accessibilityIdentifier: "maintenanceRequestDetails"
        )

        titleLabel.text = request.title
        statusLabel.text = "Status: \(request.status)"
        locationLabel.text = "Location: \(request.location)"
        submittedDateLabel.text = "Submitted: \(request.submittedDateText)"
        detailsHeadingLabel.text = "Description"
        detailsLabel.text = request.details

        carouselView.accessibilityIdentifier = "maintenancePhotoCarousel"

        [
            carouselView,
            titleLabel,
            statusLabel,
            locationLabel,
            submittedDateLabel,
            detailsHeadingLabel,
            detailsLabel
        ].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            carouselView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }

    private func configureContent() {
        let items = request.photoURLs.map(PhotoCarouselItem.url)
        carouselView.setContent(
            items.isEmpty ? .empty : .items(items),
            initialPage: 0
        )
    }

    private func makeLabel(
        style: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        color: UIColor = .label,
        accessibilityIdentifier: String? = nil
    ) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: style).withWeight(weight)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = color
        label.accessibilityIdentifier = accessibilityIdentifier
        return label
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        return UIFont(descriptor: fontDescriptor.addingAttributes([.traits: traits]), size: pointSize)
    }
}

import UIKit

final class MaintenanceRequestView: UIView {
    private let carouselView = PhotoCarouselView()
    private let titleLabel = MaintenanceRequestView.makeLabel(
        style: .title1,
        weight: .bold,
        accessibilityIdentifier: "maintenanceRequestTitle"
    )
    private let statusLabel = MaintenanceRequestView.makeLabel(
        style: .headline,
        weight: .semibold,
        color: .systemBlue,
        accessibilityIdentifier: "maintenanceRequestStatus"
    )
    private let locationLabel = MaintenanceRequestView.makeLabel(
        style: .body,
        accessibilityIdentifier: "maintenanceRequestLocation"
    )
    private let submittedDateLabel = MaintenanceRequestView.makeLabel(
        style: .subheadline,
        color: .secondaryLabel,
        accessibilityIdentifier: "maintenanceRequestSubmittedDate"
    )
    private let detailsHeadingLabel = MaintenanceRequestView.makeLabel(
        style: .headline,
        weight: .semibold,
        accessibilityIdentifier: "maintenanceRequestDetailsHeading"
    )
    private let detailsLabel = MaintenanceRequestView.makeLabel(
        style: .body,
        accessibilityIdentifier: "maintenanceRequestDetails"
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:)")
    }

    func configure(with content: MaintenanceRequestContent) {
        titleLabel.text = content.titleText
        statusLabel.text = content.statusText
        locationLabel.text = content.locationText
        submittedDateLabel.text = content.submittedDateText
        detailsHeadingLabel.text = content.detailsHeadingText
        detailsLabel.text = content.detailsText
        carouselView.setContent(content.carouselContent, initialPage: 0)
    }

    private func configureHierarchy() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        let stackView = UIStackView()

        backgroundColor = .systemBackground
        accessibilityIdentifier = "maintenanceRequestScreen"

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        carouselView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 12
        carouselView.accessibilityIdentifier = "maintenancePhotoCarousel"

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

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
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

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

    private static func makeLabel(
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

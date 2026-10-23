import UIKit

final class DemoMenuViewController: UIViewController {
    private let makeApartmentDemo: () -> UIViewController
    private let makeMaintenanceDemo: () -> UIViewController

    private(set) lazy var apartmentButton = makeButton(
        title: "Apartment Popup",
        accessibilityIdentifier: "openApartmentDemoButton",
        action: #selector(openApartmentDemo)
    )
    private(set) lazy var maintenanceButton = makeButton(
        title: "Maintenance Request",
        accessibilityIdentifier: "openMaintenanceDemoButton",
        action: #selector(openMaintenanceDemo)
    )

    init(
        makeApartmentDemo: @escaping () -> UIViewController,
        makeMaintenanceDemo: @escaping () -> UIViewController
    ) {
        self.makeApartmentDemo = makeApartmentDemo
        self.makeMaintenanceDemo = makeMaintenanceDemo
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(makeApartmentDemo:makeMaintenanceDemo:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Carousel Demos"
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "demoMenuScreen"

        let headingLabel = UILabel()
        headingLabel.font = .preferredFont(forTextStyle: .title1)
        headingLabel.adjustsFontForContentSizeCategory = true
        headingLabel.numberOfLines = 0
        headingLabel.text = "Reusable Photo Carousel"

        let descriptionLabel = UILabel()
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.text = "Choose a screen to see the same carousel used by two independent consumers."

        let stackView = UIStackView(arrangedSubviews: [
            headingLabel,
            descriptionLabel,
            apartmentButton,
            maintenanceButton
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.setCustomSpacing(28, after: descriptionLabel)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            apartmentButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            maintenanceButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }

    @objc private func openApartmentDemo() {
        navigationController?.pushViewController(makeApartmentDemo(), animated: true)
    }

    @objc private func openMaintenanceDemo() {
        navigationController?.pushViewController(makeMaintenanceDemo(), animated: true)
    }

    private func makeButton(
        title: String,
        accessibilityIdentifier: String,
        action: Selector
    ) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .large

        let button = UIButton(configuration: configuration)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

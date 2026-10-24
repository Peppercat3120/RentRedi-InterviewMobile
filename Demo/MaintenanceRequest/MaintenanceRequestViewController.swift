import UIKit

final class MaintenanceRequestViewController: UIViewController {
    private let request: MaintenanceRequest
    private let presentationBuilder: MaintenanceRequestPresentationBuilder

    init(
        request: MaintenanceRequest,
        presentationBuilder: MaintenanceRequestPresentationBuilder = MaintenanceRequestPresentationBuilder()
    ) {
        self.request = request
        self.presentationBuilder = presentationBuilder
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(request:)")
    }

    override func loadView() {
        view = MaintenanceRequestView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let content = presentationBuilder.build(request: request)
        title = content.navigationTitle
        (view as? MaintenanceRequestView)?.configure(with: content)
    }
}

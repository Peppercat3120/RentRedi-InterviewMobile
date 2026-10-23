import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let menuViewController = DemoMenuViewController(
            makeApartmentDemo: {
                let controller = ApartmentPopupViewController(
                    listingService: DemoApartmentListingService(
                        details: DemoApartmentPopupFixture.makeListingDetails()
                    ),
                    inviteStatusService: RecordingInviteStatusService(),
                    initialSubmission: DemoApartmentPopupFixture.makeSubmission()
                )
                controller.title = "Apartment Popup"
                return controller
            },
            makeMaintenanceDemo: {
                MaintenanceRequestViewController(
                    request: DemoMaintenanceRequestFixture.makeRequest()
                )
            }
        )
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(
            rootViewController: menuViewController
        )
        window.makeKeyAndVisible()
        self.window = window
    }
}

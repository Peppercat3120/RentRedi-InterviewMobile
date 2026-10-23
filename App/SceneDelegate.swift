import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let listingService = DemoApartmentListingService(
            details: DemoApartmentPopupFixture.makeListingDetails()
        )
        let inviteStatusService = RecordingInviteStatusService()
        let submission = DemoApartmentPopupFixture.makeSubmission()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = DemoViewController(
            listingService: listingService,
            inviteStatusService: inviteStatusService,
            initialSubmission: submission
        )
        window.makeKeyAndVisible()
        self.window = window
    }
}

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
            details: ApartmentListingDetails(
                bedroomCount: "2",
                bathroomCount: "2",
                monthlyRent: "2,450",
                photoURLs: DemoImageFactory.makeImageURLs()
            )
        )
        let inviteStatusService = RecordingInviteStatusService()
        let submission = DemoTenantCardSubmission(
            address: "123 Maple Street",
            unitID: "4B",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
        submission.submissionType = "application"
        submission.ownerID = "demo-owner"
        submission.propertyID = "demo-property"
        submission.renterID = "demo-renter"
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

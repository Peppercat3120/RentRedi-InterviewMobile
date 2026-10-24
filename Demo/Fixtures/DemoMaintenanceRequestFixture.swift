import Foundation

enum DemoMaintenanceRequestFixture {
    static func makeRequest() -> MaintenanceRequest {
        MaintenanceRequest(
            title: "Leaking Kitchen Sink",
            status: "Open",
            location: "Kitchen",
            submittedDateText: "October 23, 2026",
            details: "Water is dripping beneath the sink and has started to damage the cabinet base.",
            photoURLs: DemoImageProvider.maintenanceImageURLs()
        )
    }
}

import Foundation

struct MaintenanceRequest: Equatable {
    let title: String
    let status: String
    let location: String
    let submittedDateText: String
    let details: String
    let photoURLs: [URL]
}

import Foundation

struct MaintenanceRequestPresentationBuilder {
    func build(request: MaintenanceRequest) -> MaintenanceRequestContent {
        let photoItems = request.photoURLs.map(PhotoCarouselItem.url)

        return MaintenanceRequestContent(
            navigationTitle: "Maintenance Request",
            titleText: request.title,
            statusText: "Status: \(request.status)",
            locationText: "Location: \(request.location)",
            submittedDateText: "Submitted: \(request.submittedDateText)",
            detailsHeadingText: "Description",
            detailsText: request.details,
            carouselContent: photoItems.isEmpty ? .empty : .items(photoItems)
        )
    }
}

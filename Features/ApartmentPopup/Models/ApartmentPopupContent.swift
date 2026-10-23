import Foundation

struct ApartmentPopupContent {
    enum Media {
        case photos([PhotoCarouselItem])
        case defaultInvite
    }

    let title: String
    let bedroomText: String?
    let bathroomText: String?
    let addressText: String
    let regionText: String?
    let rentText: String?
    let primaryActionTitle: String
    let media: Media
}

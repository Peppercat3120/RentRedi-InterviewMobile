import UIKit

enum PhotoCarouselItem {
    case url(URL)
    case image(UIImage)
}

enum PhotoCarouselContent {
    case empty
    /// TODO: Add a distinct carousel-level progress presentation and accessibility state.
    case loading
    case items([PhotoCarouselItem])
    /// TODO: Add a distinct carousel-level error presentation and retry action.
    case failure
}

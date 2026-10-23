import UIKit

enum PhotoCarouselItem {
    case url(URL)
    case image(UIImage)
}

enum PhotoCarouselContent {
    case empty
    case loading
    case items([PhotoCarouselItem])
    case failure
}

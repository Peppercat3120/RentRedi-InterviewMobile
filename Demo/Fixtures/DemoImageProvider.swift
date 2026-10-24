import Foundation

enum DemoImageProvider {
    private static let apartmentResourceNames = [
        "apartment-living-room",
        "apartment-kitchen",
        "apartment-bedroom"
    ]

    private static let maintenanceResourceNames = [
        "maintenance-under-sink",
        "maintenance-cabinet-base",
        "maintenance-water-stain"
    ]

    static func apartmentImageURLs(bundle: Bundle = .main) -> [URL] {
        resourceURLs(named: apartmentResourceNames, bundle: bundle)
    }

    static func maintenanceImageURLs(bundle: Bundle = .main) -> [URL] {
        resourceURLs(named: maintenanceResourceNames, bundle: bundle)
    }

    private static func resourceURLs(named names: [String], bundle: Bundle) -> [URL] {
        names.compactMap { name in
            guard let url = bundle.url(forResource: name, withExtension: "png") else {
                assertionFailure("Missing bundled demo image resource: \(name).png")
                return nil
            }
            return url
        }
    }
}

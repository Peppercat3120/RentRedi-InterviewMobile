import Foundation

extension String {
    func capitalizeFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }
}

import Foundation

final class MockDatabaseReference {
    @discardableResult
    func child(_ path: String) -> MockDatabaseReference { self }
    func setValue(_ value: Any?) {}
}

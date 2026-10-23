import Foundation

final class MockDatabaseReference {
    struct Write {
        let path: String
        let value: Any?
    }

    private final class Storage {
        var writes = [Write]()
    }

    private let pathComponents: [String]
    private let storage: Storage

    var writes: [Write] { storage.writes }

    init() {
        pathComponents = []
        storage = Storage()
    }

    private init(pathComponents: [String], storage: Storage) {
        self.pathComponents = pathComponents
        self.storage = storage
    }

    @discardableResult
    func child(_ path: String) -> MockDatabaseReference {
        MockDatabaseReference(
            pathComponents: pathComponents + [path],
            storage: storage
        )
    }

    func setValue(_ value: Any?) {
        storage.writes.append(Write(path: pathComponents.joined(separator: "/"), value: value))
    }
}

import Foundation

final class DemoApartmentListingService: ApartmentListingLoading {
    enum Response {
        case success(ApartmentListingDetails)
        case failure(Error)
    }

    private let response: Response

    init(details: ApartmentListingDetails) {
        response = .success(details)
    }

    init(error: Error) {
        response = .failure(error)
    }

    func loadListingDetails(
        for identifier: ApartmentListingIdentifier
    ) async throws -> ApartmentListingDetails {
        try Task.checkCancellation()
        switch response {
        case .success(let details):
            return details
        case .failure(let error):
            throw error
        }
    }
}

actor RecordingInviteStatusService: InviteStatusUpdating {
    struct Update: Equatable {
        let status: InviteStatus
        let invite: InviteIdentifier
    }

    private(set) var updates = [Update]()
    private let error: Error?
    private var waiters = [(count: Int, continuation: CheckedContinuation<Void, Never>)]()

    init(error: Error? = nil) {
        self.error = error
    }

    func updateStatus(
        _ status: InviteStatus,
        for invite: InviteIdentifier
    ) async throws {
        updates.append(Update(status: status, invite: invite))
        resumeSatisfiedWaiters()

        if let error {
            throw error
        }
    }

    func waitUntilUpdateCount(_ count: Int) async {
        guard updates.count < count else { return }
        await withCheckedContinuation { continuation in
            waiters.append((count, continuation))
        }
    }

    private func resumeSatisfiedWaiters() {
        var pending = [(count: Int, continuation: CheckedContinuation<Void, Never>)]()
        for waiter in waiters {
            if updates.count >= waiter.count {
                waiter.continuation.resume()
            } else {
                pending.append(waiter)
            }
        }
        waiters = pending
    }
}

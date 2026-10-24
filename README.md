# RentRedi Reusable Photo Carousel

This project refactors a production-derived apartment popup to extract a reusable photo carousel, then demonstrates the same component in an independent maintenance-request screen. The demo preserves the apartment experience while separating presentation, UIKit rendering, controller coordination, and external services into maintainable boundaries.

## What is included

- An apartment popup backed by asynchronous listing and invite-status service protocols.
- A maintenance-request screen that independently consumes the shared carousel.
- Six bundled demo images loaded through the production-style asynchronous image-loading path.
- Unit, integration, and UI smoke tests covering presentation, interaction, resources, reconfiguration, and both demo routes.

## Architecture

The application uses structured MVC:

- **Models and services** hold domain data and expose asynchronous operations through focused protocols.
- **Presentation builders** convert domain values into immutable, already-formatted display content.
- **Views** own UIKit hierarchy, styling, constraints, accessibility, and content application.
- **View controllers** coordinate lifecycle, user actions, navigation, and asynchronous services.

Controllers receive collaborators through initializer injection. `SceneDelegate` is the composition root that assembles the deterministic demo services, fixtures, controllers, and routes.

## Shared carousel

`PhotoCarouselView` owns paging, collection-view behavior, and cell image presentation. Both the apartment popup and maintenance request views consume it through `PhotoCarouselContent`, while `DefaultImageLoader` provides the shared asynchronous loading path.

## Production reference

`Reference/ProductionTenantCardSubmission.swift` preserves the Firebase-coupled production model for comparison and future extraction, but is intentionally excluded from every build target. Compiling it here would pull production Firebase, authentication, and persistence responsibilities into the standalone presentation demo. For the same reason, the apartment popup's Start action only dismisses the popup: the real application/prequalification coordinator is outside this project's scope.

## Build and run

1. Open `ApartmentPopupDemo.xcodeproj` in Xcode.
2. Select the shared `ApartmentPopupDemo` scheme and an iOS 16 or newer simulator.
3. Run with **Product > Run** (`⌘R`). The demo menu provides routes to both carousel consumers.

## Tests

Run the complete unit, integration, and UI-test suite with **Product > Test** (`⌘U`).

The equivalent command-line test is:

```sh
xcodebuild test \
  -project ApartmentPopupDemo.xcodeproj \
  -scheme ApartmentPopupDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Testing boundaries

The unit and integration suite exercises presentation mapping, controller coordination, image loading, carousel behavior, and both demo consumers with deterministic services and test doubles. The UI smoke test launches the application and verifies that both demo routes expose visible, swipeable carousels.

The Firebase adapters are conditionally compiled because this standalone project does not include the Firebase SDK. Their integration tests remain intentionally deferred until Firebase and its emulator are available. That future emulator-backed suite should verify database paths, photo ordering and decoding, status writes, backend errors, and cancellation behavior. The service protocols and their consumers remain covered independently of Firebase.

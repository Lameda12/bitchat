import CoreLocation
#if os(iOS)
import UIKit
#endif

@MainActor
final class DozorAlertService: ObservableObject {
    @Published var alertRadius: Double = 1000

    func evaluate(_ sighting: DozorSighting, userLocation: CLLocation) {
        guard !sighting.isExpired else { return }
        let pinLocation = CLLocation(
            latitude: sighting.coordinate.latitude,
            longitude: sighting.coordinate.longitude
        )
        let distance = userLocation.distance(from: pinLocation)
        guard distance <= alertRadius else { return }
        triggerHaptic(for: sighting.type)
    }

    private func triggerHaptic(for type: SightingType) {
        #if os(iOS)
        switch type {
        case .checkpoint, .mobileUnit:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                generator.impactOccurred()
            }
        case .officer:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .clear:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}

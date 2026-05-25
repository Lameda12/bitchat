import CoreLocation
import Foundation

struct DozorMessageParser {
    static let prefix = "ДОЗОР:"

    static func parse(_ text: String) -> DozorSighting? {
        guard text.hasPrefix(prefix) else { return nil }
        let json = String(text.dropFirst(prefix.count))
        guard let data = json.data(using: .utf8),
              let payload = try? JSONDecoder().decode(WirePayload.self, from: data)
        else { return nil }

        return DozorSighting(
            id: UUID(),
            type: payload.t,
            coordinate: CLLocationCoordinate2D(
                latitude: payload.lat,
                longitude: payload.lng
            ),
            timestamp: Date(timeIntervalSince1970: payload.ts),
            note: payload.note,
            confidence: 1
        )
    }

    static func encode(_ sighting: DozorSighting) -> String {
        let payload = WirePayload(
            t: sighting.type,
            lat: sighting.coordinate.latitude,
            lng: sighting.coordinate.longitude,
            ts: sighting.timestamp.timeIntervalSince1970,
            note: sighting.note
        )
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8)
        else { return "" }
        return prefix + json
    }

    private struct WirePayload: Codable {
        let t: SightingType
        let lat: Double
        let lng: Double
        let ts: Double
        let note: String?
    }
}

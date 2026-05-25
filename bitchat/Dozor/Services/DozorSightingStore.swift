import CoreLocation
import Foundation

final class DozorSightingStore {
    private let key = "dozor.sightings.v1"

    func load() -> [DozorSighting] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sightings = try? JSONDecoder().decode([DozorSighting].self, from: data)
        else { return [] }
        return sightings.filter { !$0.isExpired }
    }

    func save(_ sightings: [DozorSighting]) {
        let active = sightings.filter { !$0.isExpired }
        guard let data = try? JSONEncoder().encode(active) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func append(_ sighting: DozorSighting) {
        var current = load()
        let isDuplicate = current.contains { existing in
            existing.type == sighting.type &&
            CLLocation(latitude: existing.coordinate.latitude,
                       longitude: existing.coordinate.longitude)
                .distance(from: CLLocation(latitude: sighting.coordinate.latitude,
                                           longitude: sighting.coordinate.longitude)) < 200 &&
            sighting.timestamp.timeIntervalSince(existing.timestamp) < 600
        }
        guard !isDuplicate else { return }
        current.append(sighting)
        save(current)
    }
}

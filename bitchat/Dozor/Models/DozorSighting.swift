import CoreLocation
import Foundation

enum SightingType: String, Codable {
    case checkpoint  = "checkpoint"
    case mobileUnit  = "mobile"
    case officer     = "officer"
    case clear       = "clear"

    var emoji: String {
        switch self {
        case .checkpoint: return "🔴"
        case .mobileUnit: return "🚐"
        case .officer:    return "🟡"
        case .clear:      return "✅"
        }
    }

    var localizedLabel: String {
        switch self {
        case .checkpoint: return "Блокпост"
        case .mobileUnit: return "Машина военкомата"
        case .officer:    return "Сотрудник"
        case .clear:      return "Чисто"
        }
    }
}

struct DozorSighting: Codable, Identifiable {
    let id: UUID
    let type: SightingType
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let note: String?
    var confidence: Int

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 5400
    }

    var emoji: String { type.emoji }
    var localizedLabel: String { type.localizedLabel }
}

extension CLLocationCoordinate2D: @retroactive Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lat = try container.decode(Double.self)
        let lng = try container.decode(Double.self)
        self.init(latitude: lat, longitude: lng)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
}

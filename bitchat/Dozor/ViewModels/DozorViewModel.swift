import Combine
import CoreLocation
import SwiftUI

@MainActor
final class DozorViewModel: ObservableObject {
    @Published var sightings: [DozorSighting] = []
    @Published var userLocation: CLLocation?
    @Published var isReporting = false
    @Published var currentGeohashChannel: String?

    let alertService = DozorAlertService()
    private let store = DozorSightingStore()
    private let channelService = DozorChannelService()
    private let locationTracker = UserLocationTracker()

    weak var chatViewModel: ChatViewModel?

    init() {
        sightings = store.load()
        setupChannelService()
        setupLocationTracker()
    }

    func setup(chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
        chatViewModel.dozorMessageHandler = { [weak self] text in
            Task { @MainActor in
                self?.handleIncomingMessage(text)
            }
        }
    }

    func handleIncomingMessage(_ text: String) {
        guard let sighting = DozorMessageParser.parse(text) else { return }
        store.append(sighting)
        sightings = store.load()
        if let loc = userLocation {
            alertService.evaluate(sighting, userLocation: loc)
        }
    }

    func report(type: SightingType, coordinate: CLLocationCoordinate2D, note: String?) {
        let sighting = DozorSighting(
            id: UUID(),
            type: type,
            coordinate: coordinate,
            timestamp: Date(),
            note: note,
            confidence: 1
        )
        let message = DozorMessageParser.encode(sighting)
        chatViewModel?.sendMessage(message)
        store.append(sighting)
        sightings = store.load()
    }

    private func setupLocationTracker() {
        locationTracker.onLocation = { [weak self] loc in
            Task { @MainActor in
                self?.userLocation = loc
            }
        }
        locationTracker.start()
    }

    private func setupChannelService() {
        channelService.onChannelResolved = { [weak self] geohash in
            guard let geohash else { return }
            Task { @MainActor in
                self?.currentGeohashChannel = geohash
                let channel = ChannelID.location(GeohashChannel(level: .city, geohash: geohash))
                self?.chatViewModel?.switchLocationChannel(to: channel)
            }
        }
        channelService.requestAndResolve()
    }
}

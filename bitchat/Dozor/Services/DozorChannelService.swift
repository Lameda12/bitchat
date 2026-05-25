import CoreLocation

final class DozorChannelService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var onChannelResolved: ((String?) -> Void)?

    func requestAndResolve() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        let geohash = Geohash.encode(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            precision: 5
        )
        onChannelResolved?(geohash)
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        onChannelResolved?(nil)
    }
}

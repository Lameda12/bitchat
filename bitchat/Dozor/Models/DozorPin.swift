import MapKit

final class DozorPin: NSObject, MKAnnotation {
    let sighting: DozorSighting
    var coordinate: CLLocationCoordinate2D { sighting.coordinate }
    var title: String? { sighting.emoji + " " + sighting.localizedLabel }
    var subtitle: String? { sighting.note }

    init(sighting: DozorSighting) {
        self.sighting = sighting
    }
}

import SwiftUI
#if os(iOS)
import MapKit

// MARK: - Pin view

struct DozorPinView: View {
    let sighting: DozorSighting
    @State private var appeared = false

    private var isExpired: Bool { sighting.isExpired }

    private var pinColor: Color {
        guard !isExpired else { return .gray }
        switch sighting.type {
        case .checkpoint: return Color(red: 1,    green: 0.18, blue: 0.18)
        case .mobileUnit: return Color(red: 1,    green: 0.55, blue: 0)
        case .officer:    return Color(red: 1,    green: 0.84, blue: 0)
        case .clear:      return Color(red: 0,    green: 0.78, blue: 0.33)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(isExpired ? "⚫" : sighting.emoji)
                .font(.system(size: 28))
                .shadow(color: pinColor.opacity(0.6), radius: 6)
            Text(sighting.localizedLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(pinColor)
                .clipShape(Capsule())
        }
        .opacity(appeared ? (isExpired ? 0.4 : 1.0) : 0)
        .scaleEffect(appeared ? 1 : 0.3)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - Visible sightings (removed after 105 min)

private func visibleSightings(_ sightings: [DozorSighting]) -> [DozorSighting] {
    sightings.filter { Date().timeIntervalSince($0.timestamp) < 6300 }
}

// MARK: - Channel chip

private struct ChannelChip: View {
    let geohash: String?

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 11, weight: .semibold))
            Text(geohash.map { "Район: \($0)" } ?? "Поиск района...")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Empty state overlay

private struct EmptyStateOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 36))
                .foregroundColor(.green.opacity(0.8))
            Text("Нет сигналов поблизости")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text("Зона чистая")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}

// MARK: - Settings sheet

struct DozorSettingsView: View {
    @EnvironmentObject var dozorVM: DozorViewModel
    @Environment(\.dismiss) var dismiss

    private let radiusOptions: [(String, Double)] = [
        ("500 м", 500),
        ("1 км",  1000),
        ("2 км",  2000),
        ("5 км",  5000)
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Радиус оповещения")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)

                VStack(spacing: 10) {
                    ForEach(radiusOptions, id: \.1) { label, value in
                        Button {
                            dozorVM.alertService.alertRadius = value
                        } label: {
                            HStack {
                                Text(label)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                if dozorVM.alertService.alertRadius == value {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(16)
                            .background(
                                dozorVM.alertService.alertRadius == value
                                    ? Color.red.opacity(0.15)
                                    : Color.white.opacity(0.06)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .colorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - iOS 17+ map

@available(iOS 17.0, *)
private struct MapViewiOS17: View {
    @EnvironmentObject var dozorVM: DozorViewModel
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showingReport = false
    @State private var showingSettings = false

    private var visible: [DozorSighting] { visibleSightings(dozorVM.sightings) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $position) {
                UserAnnotation()
                ForEach(visible) { sighting in
                    Annotation(sighting.localizedLabel, coordinate: sighting.coordinate) {
                        DozorPinView(sighting: sighting)
                    }
                }
                if let loc = dozorVM.userLocation {
                    MapCircle(center: loc.coordinate, radius: dozorVM.alertService.alertRadius)
                        .foregroundStyle(Color.red.opacity(0.08))
                        .stroke(Color.red.opacity(0.35), lineWidth: 1.5)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .colorScheme(.dark)
            .ignoresSafeArea()

            // Top bar: channel chip + settings button
            VStack {
                HStack {
                    ChannelChip(geohash: dozorVM.currentGeohashChannel)
                    Spacer()
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
                Spacer()
            }

            // Empty state (centred)
            if visible.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateOverlay()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }

            // FAB
            Button {
                showingReport = true
            } label: {
                Label("Сообщить", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .shadow(color: .red.opacity(0.4), radius: 12, y: 4)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingReport) {
            DozorReportView().environmentObject(dozorVM)
        }
        .sheet(isPresented: $showingSettings) {
            DozorSettingsView().environmentObject(dozorVM)
        }
    }
}

// MARK: - iOS 16 fallback

private struct MapViewLegacy: UIViewRepresentable {
    let sightings: [DozorSighting]
    let userLocation: CLLocation?
    let alertRadius: Double

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.overrideUserInterfaceStyle = .dark
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        map.removeOverlays(map.overlays)
        let pins = visibleSightings(sightings).map { DozorPin(sighting: $0) }
        map.addAnnotations(pins)
        if let loc = userLocation {
            map.addOverlay(MKCircle(center: loc.coordinate, radius: alertRadius))
        }
    }
}

// MARK: - Public view

struct DozorMapView: View {
    @EnvironmentObject var dozorVM: DozorViewModel
    @State private var showingReport = false
    @State private var showingSettings = false

    private var visible: [DozorSighting] { visibleSightings(dozorVM.sightings) }

    var body: some View {
        if #available(iOS 17.0, *) {
            MapViewiOS17().environmentObject(dozorVM)
        } else {
            ZStack(alignment: .bottomTrailing) {
                MapViewLegacy(
                    sightings: dozorVM.sightings,
                    userLocation: dozorVM.userLocation,
                    alertRadius: dozorVM.alertService.alertRadius
                )
                .colorScheme(.dark)
                .ignoresSafeArea()

                VStack {
                    HStack {
                        ChannelChip(geohash: dozorVM.currentGeohashChannel)
                        Spacer()
                        Button { showingSettings = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
                    Spacer()
                }

                if visible.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateOverlay()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                }

                Button { showingReport = true } label: {
                    Label("Сообщить", systemImage: "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .shadow(color: .red.opacity(0.4), radius: 12, y: 4)
                }
                .padding(24)
            }
            .sheet(isPresented: $showingReport) {
                DozorReportView().environmentObject(dozorVM)
            }
            .sheet(isPresented: $showingSettings) {
                DozorSettingsView().environmentObject(dozorVM)
            }
        }
    }
}

#else
struct DozorPinView: View {
    let sighting: DozorSighting
    var body: some View { Text(sighting.emoji) }
}

struct DozorMapView: View {
    var body: some View { Text("Радар (iOS only)") }
}

struct DozorSettingsView: View {
    var body: some View { Text("Settings (iOS only)") }
}
#endif

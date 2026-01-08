import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import UIKit

struct MapScreen: View {
    @Query private var places: [Place]

    @StateObject private var locationManager = LocationManager()

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedPlace: Place?

    @State private var showLocationAlert = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Map(position: $cameraPosition, selection: $selectedPlace) {
                    ForEach(places) { place in
                        Marker(place.name, coordinate: place.coordinate)
                            .tag(place)
                    }
                }
                .navigationTitle("Map")
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .sheet(item: $selectedPlace) { place in
                    PlaceDetailScreen(place: place)
                }

                // Custom "My Location" button (replaces MapUserLocationButton)
                Button {
                    handleMyLocationTap()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .accessibilityLabel("My Location")
            }
            .alert("Location Access Needed", isPresented: $showLocationAlert) {
                if locationManager.authorizationStatus == .notDetermined {
                    Button("Allow Location") {
                        locationManager.requestPermission()
                    }
                    Button("Not Now", role: .cancel) { }
                } else {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } message: {
                if locationManager.authorizationStatus == .notDetermined {
                    Text("To show your live location on the map, allow location access.")
                } else {
                    Text("Location is disabled for this app. Turn it on in Settings to show your live location.")
                }
            }
        }
    }

    private func handleMyLocationTap() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // Show alert that leads to the system permission prompt
            showLocationAlert = true

        case .denied, .restricted:
            // Show alert that leads to Settings
            showLocationAlert = true

        case .authorizedWhenInUse, .authorizedAlways:
            // Get one location reading and center the map
            locationManager.startUpdatingLocation()

            // If we already have a recent one, center immediately.
            if let loc = locationManager.lastLocation {
                centerMap(on: loc.coordinate)
            } else {
                // Otherwise center when it arrives (LocationManager stops updates after one fix)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let loc = locationManager.lastLocation {
                        centerMap(on: loc.coordinate)
                    }
                }
            }

        @unknown default:
            showLocationAlert = true
        }
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    }
}


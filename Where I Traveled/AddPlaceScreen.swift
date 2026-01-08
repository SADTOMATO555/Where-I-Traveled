import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation
import UIKit

struct AddPlaceScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var locationManager = LocationManager()

    enum LocationMethod: String, CaseIterable, Identifiable {
        case current = "Use Current Location"
        case search = "Search & Pick"
        var id: String { rawValue }
    }

    @State private var method: LocationMethod = .current

    // Place info
    @State private var name = ""
    @State private var country = ""
    @State private var notes = ""
    @State private var visitedOn = Date()

    // Photo
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?

    // Search picker
    @State private var showSearchSheet = false
    @State private var pickedResult: PlaceSearchSheet.SearchResult?
    @State private var foundCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("Name (e.g., Tokyo)", text: $name)
                    TextField("Country/Region (e.g., Japan)", text: $country)
                    DatePicker("Visited On", selection: $visitedOn, displayedComponents: .date)
                }

                Section("Pin Method") {
                    Picker("Method", selection: $method) {
                        ForEach(LocationMethod.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: method) { _, newValue in
                        if newValue == .current {
                            // Clear search selection
                            pickedResult = nil
                            foundCoordinate = nil
                        } else {
                            // Stop GPS updates when switching away
                            locationManager.stopUpdatingLocation()
                        }
                    }
                }

                if method == .current {
                    currentLocationSection
                } else {
                    searchPickSection
                }

                Section("Photo") {
                    PhotosPicker("Choose Photo", selection: $pickerItem, matching: .images)

                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Add Place")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run { self.photoData = data }
                    }
                }
            }
            .sheet(isPresented: $showSearchSheet) {
                PlaceSearchSheet { result in
                    pickedResult = result
                    foundCoordinate = result.coordinate

                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        name = result.name
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var currentLocationSection: some View {
        Section("Current Location") {
            currentLocationStatusView

            Button {
                handleCurrentLocationButton()
            } label: {
                Text(currentLocationButtonTitle)
            }
        }
    }

    private var searchPickSection: some View {
        Section("Search & Pick") {
            Button("Search for a place") {
                showSearchSheet = true
            }

            if let pickedResult, let coord = foundCoordinate {
                Text("Selected: \(pickedResult.name)")
                    .font(.subheadline)

                Text("Pin: \(coord.latitude, specifier: "%.5f"), \(coord.longitude, specifier: "%.5f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No place selected yet.")
                    .foregroundStyle(.secondary)
            }

            Text("Tip: Use 'City, Country' for best results (e.g., 'Rome, Italy').")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Save rules

    private var canSave: Bool {
        let basicsOK =
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let hasCoordinate: Bool = {
            switch method {
            case .current:
                return locationManager.lastLocation != nil
            case .search:
                return foundCoordinate != nil
            }
        }()

        return basicsOK && hasCoordinate
    }

    private func save() {
        let coordinate: CLLocationCoordinate2D? = {
            switch method {
            case .current:
                return locationManager.lastLocation?.coordinate
            case .search:
                return foundCoordinate
            }
        }()

        guard let coordinate else { return }

        let place = Place(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes,
            visitedOn: visitedOn,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            photoData: photoData
        )

        modelContext.insert(place)
        try? modelContext.save()
        dismiss()
    }

    // MARK: - Current location helpers

    private var currentLocationButtonTitle: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Allow Location Access"
        case .denied, .restricted:
            return "Location Disabled (Open Settings)"
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.isUpdating ? "Getting Location..." : "Use Current Location"
        @unknown default:
            return "Use Current Location"
        }
    }

    @ViewBuilder
    private var currentLocationStatusView: some View {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            Text("Location permission not set yet.")
                .foregroundStyle(.secondary)

        case .denied, .restricted:
            Text("Location access is disabled. Enable it in Settings to save your current location.")
                .foregroundStyle(.secondary)

        case .authorizedWhenInUse, .authorizedAlways:
            if let loc = locationManager.lastLocation {
                Text("Captured: \(loc.coordinate.latitude, specifier: "%.5f"), \(loc.coordinate.longitude, specifier: "%.5f")")
                    .foregroundStyle(.secondary)
            } else if locationManager.isUpdating {
                Text("Finding your location…")
                    .foregroundStyle(.secondary)
            } else {
                Text("No location captured yet.")
                    .foregroundStyle(.secondary)
            }

        @unknown default:
            Text("Unknown authorization status.")
                .foregroundStyle(.secondary)
        }

        if let msg = locationManager.lastErrorMessage {
            Text("Error: \(msg)")
                .foregroundStyle(.secondary)
        }
    }

    private func handleCurrentLocationButton() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()

        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()

        @unknown default:
            break
        }
    }
}


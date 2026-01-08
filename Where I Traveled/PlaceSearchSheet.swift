import SwiftUI
import MapKit
import CoreLocation

struct PlaceSearchSheet: View {
    @Environment(\.dismiss) private var dismiss

    struct SearchResult: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    let onSelect: (SearchResult) -> Void

    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }

                if isSearching {
                    Text("Searching…")
                        .foregroundStyle(.secondary)
                }

                ForEach(results) { r in
                    Button {
                        onSelect(r)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(r.name)
                                .font(.headline)

                            Text("\(r.coordinate.latitude, specifier: "%.5f"), \(r.coordinate.longitude, specifier: "%.5f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Search Places")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .searchable(text: $query, prompt: "City, country, landmark…")
            .onChange(of: query) { _, newValue in
                runSearchDebounced(for: newValue)
            }
        }
    }

    private func runSearchDebounced(for text: String) {
        searchTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s debounce
            if Task.isCancelled { return }
            await runSearch(query: trimmed)
        }
    }

    @MainActor
    private func runSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        results = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(request: request).start()

            // Convert MKMapItems into safe, stable results
            let mapped: [SearchResult] = response.mapItems.compactMap { item in
                let name = item.name ?? query
                let coord = item.location.coordinate  // location is non-optional in your SDK
                return SearchResult(name: name, coordinate: coord)
            }

            results = mapped

            if results.isEmpty {
                errorMessage = "No results. Try adding more detail (e.g., 'Paris, France')."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }
}


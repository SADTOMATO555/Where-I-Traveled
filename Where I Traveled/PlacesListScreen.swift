import SwiftUI
import SwiftData

struct PlacesListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.visitedOn, order: .reverse) private var places: [Place]

    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [Place] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return places }
        return places.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { place in
                    NavigationLink {
                        PlaceDetailScreen(place: place)
                    } label: {
                        PlaceRow(place: place)
                    }
                }
                .onDelete(perform: deletePlaces)
            }
            .navigationTitle("Visited Places")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddPlaceScreen()
            }
        }
    }

    private func deletePlaces(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
        try? modelContext.save()
    }
}

struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 12) {
            if let data = place.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name).font(.headline)
                Text(place.country).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            Text(place.visitedOn, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}


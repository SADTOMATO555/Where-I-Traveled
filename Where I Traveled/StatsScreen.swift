import SwiftUI
import SwiftData

struct StatsScreen: View {
    @Query private var places: [Place]

    var uniqueCountries: Int {
        Set(places.map { $0.country.lowercased().trimmingCharacters(in: .whitespaces) }).count
    }

    var body: some View {
        NavigationStack {
            List {
                HStack {
                    Text("Places Visited")
                    Spacer()
                    Text("\(places.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Countries/Regions")
                    Spacer()
                    Text("\(uniqueCountries)")
                        .foregroundStyle(.secondary)
                }

                Section("Badges (example)") {
                    BadgeRow(title: "Explorer", subtitle: "Add 5 places", achieved: places.count >= 5)
                    BadgeRow(title: "Globetrotter", subtitle: "Add 20 places", achieved: places.count >= 20)
                    BadgeRow(title: "World Class", subtitle: "Add 50 places", achieved: places.count >= 50)
                }
            }
            .navigationTitle("Stats")
        }
    }
}

struct BadgeRow: View {
    let title: String
    let subtitle: String
    let achieved: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achieved ? "checkmark.seal.fill" : "seal")
                .foregroundStyle(achieved ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}


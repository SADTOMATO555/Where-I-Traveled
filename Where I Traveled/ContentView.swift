import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapScreen()
                .tabItem { Label("Map", systemImage: "map") }

            PlacesListScreen()
                .tabItem { Label("Places", systemImage: "list.bullet") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
    }
}


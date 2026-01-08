import Foundation
import SwiftData
import CoreLocation

@Model
final class Place {
    var id: UUID
    var name: String
    var country: String
    var notes: String
    var visitedOn: Date

    // Location
    var latitude: Double
    var longitude: Double

    // Store image data (simple approach). For many photos, consider separate Photo model.
    var photoData: Data?

    init(
        name: String,
        country: String,
        notes: String = "",
        visitedOn: Date = .now,
        latitude: Double,
        longitude: Double,
        photoData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.notes = notes
        self.visitedOn = visitedOn
        self.latitude = latitude
        self.longitude = longitude
        self.photoData = photoData
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


import SwiftUI
import SwiftData
import PhotosUI

struct EditPlaceScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let place: Place

    @State private var name: String
    @State private var country: String
    @State private var notes: String
    @State private var visitedOn: Date

    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?

    init(place: Place) {
        self.place = place
        _name = State(initialValue: place.name)
        _country = State(initialValue: place.country)
        _notes = State(initialValue: place.notes)
        _visitedOn = State(initialValue: place.visitedOn)
        _photoData = State(initialValue: place.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("Name", text: $name)
                    TextField("Country/Region", text: $country)
                    DatePicker("Visited On", selection: $visitedOn, displayedComponents: .date)
                }

                Section("Photo") {
                    PhotosPicker("Change Photo", selection: $pickerItem, matching: .images)

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
            .navigationTitle("Edit Place")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges() }
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
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveChanges() {
        place.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        place.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        place.notes = notes
        place.visitedOn = visitedOn
        place.photoData = photoData

        try? modelContext.save()
        dismiss()
    }
}


import SwiftUI

struct PreferencesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var interestsText: String
    @State private var typesText: String
    @State private var isSaving = false

    init(profile: Profile = UserManager.shared.profile ?? .zeroCustomer()) {
        _interestsText = State(initialValue: profile.preferences.interests.joined(separator: "\n"))
        _typesText = State(initialValue: profile.preferences.preferredBusinessTypes.joined(separator: "\n"))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Interests")) {
                    TextEditor(text: $interestsText)
                        .frame(minHeight: 100)
                }
                Section(header: Text("Preferred Business Types")) {
                    TextEditor(text: $typesText)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let interests = interestsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let types = typesText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        FirestoreManager.shared.updateProfile(
            data: [ProfileKey.interests: interests,
                   ProfileKey.preferredBusinessTypes: types]
        ) { success in
            if success {
                if var profile = UserManager.shared.profile {
                    profile.preferences.interests = interests
                    profile.preferences.preferredBusinessTypes = types
                    UserManager.shared.profile = profile
                }
            }
            isSaving = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

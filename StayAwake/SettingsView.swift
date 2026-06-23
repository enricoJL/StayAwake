import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderMinutes") private var reminderMinutes: Double = 60
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    private let reminderOptions: [(label: String, value: Double)] = [
        ("15 min", 15),
        ("30 min", 30),
        ("1 h", 60),
        ("2 h", 120),
        ("4 h", 240),
        ("Illimité", 0)
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Lancer StayAwake au démarrage", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
            }

            Section("Désactivation automatique après :") {
                Picker("Délai avant désactivation", selection: $reminderMinutes) {
                    ForEach(reminderOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if reminderMinutes == 0 {
                    Text("StayAwake restera actif indéfiniment. Une notification vous avertira si le Mac passe sur batterie.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("StayAwake s'éteindra automatiquement après ce délai. Une notification vous préviendra avant la désactivation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 320)
    }
}

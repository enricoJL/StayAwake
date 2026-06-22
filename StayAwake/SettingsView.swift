import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderMinutes") private var reminderMinutes: Double = 60
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    private let reminderOptions: [(label: String, value: Double)] = [
        ("15 min", 15),
        ("30 min", 30),
        ("1 h", 60),
        ("2 h", 120),
        ("4 h", 240)
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Lancer StayAwake au démarrage", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
            }

            Section("Rappel si la veille est bloquée depuis :") {
                Picker("Délai de rappel", selection: $reminderMinutes) {
                    ForEach(reminderOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text("Une notification s'affichera après ce délai si StayAwake est toujours actif.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 280)
    }
}

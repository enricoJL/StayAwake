import Cocoa
import UserNotifications
import ServiceManagement
import Combine
import IOKit.pwr_mgt

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var assertionID: IOPMAssertionID = 0
    private var reminderTimer: Timer?
    private var startTime: Date?

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    private let reminderMinutesKey = "reminderMinutes"
    private let autoStartKey = "launchAtLogin"

    private var reminderMinutes: Double {
        defaults.double(forKey: reminderMinutesKey) == 0 ? 60 : defaults.double(forKey: reminderMinutesKey)
    }

    private var isActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard granted else { return }
                self?.showNotification(
                    title: "StayAwake est désactivé",
                    body: "Cliquez sur l'icône dans la barre de menu pour empêcher la veille."
                )
            }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateTrayIcon()
        syncLoginItem()
        observeDefaults()
    }

    func applicationWillTerminate(_ notification: Notification) {
        deactivate()
    }

    // MARK: - Activation / désactivation

    private func activate() {
        guard !isActive else { return }

        let reason = "StayAwake empêche la veille" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            showNotification(title: "Erreur StayAwake", body: "Impossible de bloquer la veille.")
            return
        }

        isActive = true
        startTime = Date()
        updateTrayIcon()
        scheduleReminder()
        showNotification(title: "StayAwake activé", body: "Votre Mac restera éveillé.")
    }

    private func deactivate() {
        guard isActive else { return }

        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
        startTime = nil
        reminderTimer?.invalidate()
        reminderTimer = nil
        updateTrayIcon()
        showNotification(title: "StayAwake désactivé", body: "Votre Mac peut maintenant se mettre en veille.")
    }

    // MARK: - UI

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            if isActive { deactivate() } else { activate() }
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let title = isActive ? "Désactiver StayAwake" : "Activer StayAwake"
        let toggleItem = NSMenuItem(title: title, action: #selector(toggleFromMenu), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        if isActive, let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            let item = NSMenuItem(title: "Actif depuis \(Self.formatDuration(elapsed))", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let reminderItem = NSMenuItem(title: "Rappel après : \(Int(reminderMinutes)) min", action: nil, keyEquivalent: "")
        reminderItem.isEnabled = false
        menu.addItem(reminderItem)

        let settingsItem = NSMenuItem(title: "Réglages…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quitter StayAwake", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleFromMenu() {
        if isActive { deactivate() } else { activate() }
    }

    private func updateTrayIcon() {
        let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .regular)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "StayAwake")?
            .withSymbolConfiguration(config)
            ?? NSImage(named: isActive ? "TrayActive" : "TrayInactive")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.imageScaling = .scaleProportionallyUpOrDown
    }

    // MARK: - Rappel

    private func scheduleReminder() {
        reminderTimer?.invalidate()
        let interval = reminderMinutes * 60
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            self.showNotification(
                title: "StayAwake est toujours actif",
                body: "La veille est bloquée depuis \(Int(self.reminderMinutes)) minutes."
            )
        }
    }

    // MARK: - Notifications

    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Réglages et defaults

    private func observeDefaults() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isActive { self.scheduleReminder() }
                self.syncLoginItem()
            }
            .store(in: &cancellables)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        deactivate()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Lancement au démarrage

    private var lastSyncedLoginState: Bool?

    private func syncLoginItem() {
        let desired = defaults.bool(forKey: autoStartKey)
        guard desired != lastSyncedLoginState else { return }
        lastSyncedLoginState = desired
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if desired {
                    if service.status != .enabled { try service.register() }
                } else {
                    try service.unregister()
                }
            } catch {
                print("Login item error: \(error)")
            }
        }
    }

    // MARK: - Utilitaires

    private static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

# StayAwake

Application macOS native (Swift / SwiftUI / AppKit) qui empêche le Mac de tomber en veille pendant les présentations ou les cours.

## Fonctionnalités

- Icône dans la barre de menu (tray)
- Clic gauche : activer / désactiver `caffeinate`
- Clic droit : menu avec durée écoulée, réglages et quitter
- Notification système après un délai réglable (15 min, 30 min, 1 h, 2 h, 4 h) si StayAwake est toujours actif
- Option de lancement au démarrage
- L'état actif/inactif est mémorisé entre les lancements

## Fichiers

```
StayAwake/
├── StayAwake/
│   ├── StayAwakeApp.swift            # Point d'entrée SwiftUI
│   ├── AppDelegate.swift             # Logique menu bar + caffeinate
│   ├── SettingsWindowController.swift # Fenêtre de réglages
│   ├── SettingsView.swift            # UI des préférences
│   ├── StayAwake.entitlements        # Sandboxing
│   ├── Info.plist                    # LSUIElement (app sans dock)
│   └── Assets.xcassets/              # Icônes
├── StayAwake.xcodeproj               # Projet Xcode (à créer)
└── README.md
```

## Prérequis

- macOS 12.0 ou ultérieur
- Xcode 14 ou ultérieur
- Un compte Apple ID (gratuit suffit pour usage local)

## Créer le projet Xcode

Comme le projet Xcode n'est pas fourni en tant que fichier binaire, il faut l'importer dans Xcode :

1. Ouvrir **Xcode**.
2. `File` → `New` → `Project` → `macOS` → `App`.
3. Configurer :
   - **Product Name** : `StayAwake`
   - **Team** : ton Apple ID / équipe
   - **Organization Identifier** : `com.enrico` (ou ce que tu préfères)
   - **Interface** : `SwiftUI`
   - **Language** : `Swift`
   - Décoche `Include Tests` si tu veux un projet minimal.
4. Choisir le dossier `StayAwake/StayAwake/` comme emplacement du projet.
5. Remplacer les fichiers générés par ceux présents ici (`StayAwakeApp.swift`, `AppDelegate.swift`, etc.).
6. Ajouter `StayAwake.entitlements` et `Info.plist` au projet (glisser-déposer dans Xcode, cocher `Copy items if needed`).
7. Importer `Assets.xcassets` si ce n'est pas déjà fait.

## Configurer le projet

1. Sélectionner le projet `StayAwake` dans le navigateur.
2. Onglet **Signing & Capabilities** :
   - Coche `App Sandbox`.
   - Ajoute la capacité `UserNotifications`.
3. Onglet **Info** :
   - Ajouter la clé `LSUIElement` avec valeur `YES` (l'application n'apparaît pas dans le Dock).
4. Onglet **Build Settings** :
   - `INFOPLIST_FILE` = `StayAwake/Info.plist`
   - `CODE_SIGN_ENTITLEMENTS` = `StayAwake/StayAwake.entitlements`

## Build

- `Cmd+B` pour compiler.
- `Cmd+R` pour exécuter localement.

## Archiver / distribuer

1. `Product` → `Archive`.
2. Dans Organizer, choisir `Distribute App` → `Copy App` ou `Upload to Notarization Service`.
3. Pour un usage local seul, `Copy App` suffit.

## Lancer au login

La fonction `launchAtLogin` utilise `SMAppService` (macOS 13+). Sur macOS 12, elle tente d'enregistrer un helper de login. Pour que cela fonctionne en production, il faut :

- Signer l'application avec un compte développeur Apple payant pour la distribution.
- Ou, pour un usage personnel, autoriser manuellement l'app dans `Réglages système` → `Général` → `Ouverture à la session`.

## Icône

L'icône d'application et les icônes de tray doivent être ajoutées dans `Assets.xcassets` :

- `AppIcon` : images aux tailles 16×16 à 512×512 @1x/@2x.
- `TrayActive` : icône de menu bar quand `caffeinate` est actif.
- `TrayInactive` : icône de menu bar quand inactif.

En l'absence d'images personnalisées, l'app utilise les symboles SF `cup.and.saucer.fill` / `cup.and.saucer`.

## Notes

- `caffeinate` est un outil système macOS (`/usr/bin/caffeinate`). L'app le lance avec les arguments `-dims` (disque, idle, écran).
- L'option d'auto-démarrage nécessite des ajustements selon la version de macOS et le type de signature.

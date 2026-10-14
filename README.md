# 🛍️ Market Mate

Market Mate is a Flutter app that helps visitors discover events, explore stands on an interactive map, and coordinate with friends through teams and location sharing.

---

## 🚀 Features

- **Authentication & Profiles**: Email/password login, Apple Sign-In, and guided profile setup with avatar selection.
- **Event Discovery**: Browse events, open details, and join events.
- **Event Details**: Images, dates, organizer info, ticket price, opening hours, and a location map.
- **Map & Stands**: Stand search, category grouping, and interactive Google Map markers.
- **Favorites**: Save favorite events or stands for quick access.
- **Teams**: Create or join teams, share location, and coordinate at events.
- **Admin Tools**: Admin-only panel for creating events (with categories and image uploads).

---

## 🎨 Brand

Logo, colours, fonts and tone of voice for every public appearance: see [`brand/README.md`](brand/README.md) (visual overview: `brand/index.html`).

---

## 🛠️ Project Setup

### Prerequisites
- **Flutter**: [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart**: Comes bundled with Flutter.
- **Azure DevOps**: Ensure you have access to the repository in Azure Repos.

### Clone the Repository
```bash
git clone https://tdwdevelopments@dev.azure.com/tdwdevelopments/event_map_app/_git/event_map_app
cd event_map_app
```
### Install Dependencies
Run the following command to fetch all required packages:
```bash
flutter pub get
```
---
### Run the App
1. Connect a device or start an emulator.
2. Use the following command to run the app:
   ```bash
   flutter run
   ```
---

## 📂 File Structure

```plaintext
lib/
├── main.dart                   # Application entry point
├── data/                       # Data models (events, stands, teams, profiles)
├── features/                   # Feature-specific code (auth, events, teams, stands)
├── providers/                  # Riverpod state providers
├── screens/                    # App screens and layouts
├── services/                   # Firebase and domain services
├── utils/                      # Helper widgets and utilities
assets/                         # Assets (images, icons, fonts)
```

---

## 🔧 Development Workflow

### Branching Strategy
We follow a simplified GitFlow branching strategy:
- `main`: Production-ready code.
- `develop`: Integration branch for features.
- `feature/*`: Feature-specific branches.

### Commit Guidelines
- **Format**: `[Feature]: Add user authentication`
- Use meaningful and concise commit messages.

### Pull Requests
- Create pull requests from `feature/*` to `develop`.
- Ensure all CI checks pass before merging.

---

## 🧩 Key Packages and Plugins

- **Maps Integration**: `google_maps_flutter` or `mapbox_gl`
- **State Management**: `provider`, `riverpod`, or `flutter_bloc`
- **Firebase**:
    - `firebase_auth` for authentication
    - `cloud_firestore` for data storage
    - `firebase_messaging` for notifications
- **Utilities**:
    - `permission_handler` for managing permissions
    - `flutter_secure_storage` for sensitive data
    - `shared_preferences` for local storage

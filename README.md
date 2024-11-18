# 🎄 Christmas Market Event App

Welcome to the Christmas Market Event App! This Flutter-based application is designed to enhance the experience of visitors to Christmas markets by providing interactive features like market maps, stand listings, and real-time location sharing with friends.

---

## 🚀 Features

- **Interactive Market Map**: View a detailed map of Christmas markets.
- **Stand Listings**: Explore the available stands with descriptions, categories, and locations.
- **Real-Time Location Sharing**: Share your location with friends in the market.
- **User Authentication**: Secure login with email/password and social media options.
- **Notifications**: Stay updated with push notifications about market events and announcements.

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
├── core/                       # Core utilities (constants, themes)
├── data/                       # Data models and repositories
├── features/                   # Feature-specific code (auth, map, stands)
├── shared/                     # Reusable widgets
├── services/                   # Global services (location, Firebase)
├── utils/                      # Helper functions and utilities
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
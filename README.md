# 🎄 Market Mate

**Market Mate** is a Flutter application that currently serves as a lean starting point for a community event app. The focus right now is on a stable Flutter foundation with Firebase initialization. This README reflects the **current state** of the repository and clarifies what is implemented today versus what may come next.

---

## ✅ Current Status (As-Is)

- **Flutter app with Firebase initialization** is in place.
- **Minimal start screen** showing “Firebase Initialized!”.
- **Firebase configuration** is set up via `firebase_options.dart`.

The files in this repository indicate that the app is still in a very early phase. Functional features (e.g., maps, authentication, events, location sharing) are **not implemented yet**.

---

## 🚀 Features (Currently Available)

- **Firebase initialization** on app start.
- **Basic start screen** to confirm the connection.

---

## 🧩 Technology Stack

- **Flutter** (app framework)
- **Dart** (programming language)
- **Firebase** (backend/services)
- **Riverpod** (state management, available in dependencies)

---

## 📦 Project Setup

### Prerequisites
- Flutter SDK installed (includes Dart)
- Firebase setup via FlutterFire CLI (if you use your own Firebase project)

### Clone the repository
```bash
git clone https://tdwdevelopments@dev.azure.com/tdwdevelopments/event_map_app/_git/event_map_app
cd event_map_app
```

### Install dependencies
```bash
flutter pub get
```

---

## ▶️ Run the app

1. Start an emulator or connect a device.
2. Run the app:

```bash
flutter run
```

---

## 🔥 Firebase Configuration

Firebase options are already included in the repository (`lib/firebase_options.dart`).
If you want to use your own Firebase project, regenerate the file via the FlutterFire CLI:

```bash
flutterfire configure
```

---

## 📂 Repository Structure (As-Is)

```plaintext
android/
ios/
linux/
macos/
web/
windows/
lib/
├── main.dart                   # App entry point & Firebase init
├── firebase_options.dart       # Firebase configuration
test/
```

---

## ✅ Possible Next Steps (Roadmap Suggestion)

These items are **not implemented** yet, but could be good next steps:

- ✅ User authentication (e.g., Firebase Auth)
- ✅ Event / market listings
- ✅ Interactive map view
- ✅ Location sharing
- ✅ Push notifications

---

## 📌 Note

This README reflects the **current code state**. If specific features are planned, this document can be expanded or refined at any time.

<p align="center">
  <img src="assets/images/readme_logo.jpg" alt="WorkSpace Logo" width="120" style="border-radius: 24px;" />
</p>

<h1 align="center">WorkSpace</h1>

<p align="center">
  <strong>مساحتك . تنظيمك . إنتاجيتك</strong><br>
  An elegant, high-performance workspace container built with Flutter & Firebase.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-^3.9.2-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black&style=flat-square" alt="Firebase" />
  <img src="https://img.shields.io/badge/State--Mgmt-Riverpod-7452FF?style=flat-square" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-Web%20%28PWA%29-00C7B7?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/Language-Arabic%20%28RTL%29-E3B119?style=flat-square" alt="Language" />
</p>

**WorkSpace** is a production-ready, high-performance Progressive Web Application (PWA) built using Flutter and Firebase. It serves as an all-in-one personal station for managing, categorizing, and instantly searching resources like notes, templates, scripts, code snippets, URLs, API endpoints, and credentials. Fully localized in Egyptian Arabic.

---

## ✨ Features & UX Enhancements

* **⚡ Command Palette (`Ctrl + K`)**: Instant search overlay across the entire system. Supports full keyboard navigation (`Arrow Up / Down` to navigate, `Enter ⏎` to open).
* **🖱️ Hover Interactions**: Elements subtly lift by `-3px` on mouse hover with an glowing primary borders.
* **🔑 Account Management**: Mask/reveal password toggles directly on preview cards.
* **📋 Quick Actions**: Instant header-row copying for snippets, links and passwords without reloading pages.
* **💾 Contextual Save Controls**: Relocated actions direct-under forms for optimal workflow.
* **📂 Folder Structure separation**: Separated container workspaces (Projects) and elements (Items).
* **📦 PWA Support**: Optimized assets, manifest configurations, and custom web favicons for browser tabs.

---

## 🛠️ Tech Stack

* **Frontend**: Flutter Web (Cairo Google Font, RTL localization)
* **State Management**: flutter_riverpod (v2)
* **Routing**: go_router
* **Backend**: Firebase Auth (Google Sign-In) & Cloud Firestore
* **Styling**: AppColors Design System (Dark Slate `#0F1115` & Gold Primary `#E3B119`)

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK `^3.9.2`
* Firebase CLI installed (`npm install -g firebase-tools`)

### Setup and Running

1. Clone this repository to your local development machine.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development server locally:
   ```bash
   flutter run -d chrome
   ```

### Deploying Firestore Rules & Indexes

Workbench relies on complex queries and security constraints. Run these commands to synchronize your Firebase security settings and composite indexes:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## 📂 Codebase Anatomy

```
lib/
├── core/                         # Core utilities, constants, shared widgets, and routers
│   ├── constants/                # Global style constants (Colors, Text Styles)
│   ├── router/                   # Navigation paths and router configurations
│   └── widgets/                  # App-wide widgets (ShellScaffold, CommandPalette)
│
└── features/                     # Feature directories containing Clean Architecture layers
    ├── auth/                     # Authentication workflow (Sign-In page, Google Providers)
    ├── home/                     # Dynamic Home Dashboard (Metrics, Pinned items, recent history)
    ├── items/                    # Item entity lifecycle (Notes, links, code, APIs, credentials)
    ├── projects/                 # Project container manager
    ├── search/                   # Client-side filtering & search screens
    └── settings/                 # App parameters (Stats, profile, signout)
```


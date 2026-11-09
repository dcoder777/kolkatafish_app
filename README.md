# KolkataFish - Fresh Fish & Seafood Delivery App 🐟

A cross-platform Flutter mobile application for **[KolkataFish](https://kolkatafish.com)** — Kolkata's premier online store delivering fresh, chemical-free fish, freshwater catches, and premium seafood straight to customers' doorsteps.

---

## 📱 Features

### 🛒 Product Catalog & Discovery
- **Comprehensive Seafood Categories**: Freshwater fish (Rui, Katla, Ilish, etc.), sea fish (Bhetki, Pomfret), prawns, crabs, and more.
- **Detailed Product Specifications**: Displays Gross Weight, Net Weight (After Cut), Number of Pieces, and Fish Size parsed dynamically from WooCommerce product attributes.
- **Dynamic Search & Suggestions**: Fast keyword search with curated popular search chips.
- **Rich Media & Banners**: Promotional hero banners, trust badges, and optimized cached images.

### 💳 Cart, Offers & Checkout
- **Smart Coupons & Discounts**: Real-time integration with store coupons (e.g. `special10`, `fbkfcs05`, `fbkfcs10`) with live validation, apply/remove actions, and bill summary breakdowns.
- **Scheduled Delivery Slots**: Dynamic delivery date and time slot selector powered by `kolkatafish_get_delivery_slots` Ajax handler with pincode validation.
- **WooCommerce Admin Sync**: Formats delivery dates (`dd/mm/yy`) and slots into order metadata (`add_delivery_date`, `add_delivery_time`) ensuring order filters work out of the box in the WooCommerce admin dashboard.
- **Flexible Payment Options**: Cash on Delivery (COD) and Online/UPI payments.

### 👤 Authentication & Persistence
- **Always-Logged-In Experience**: Synchronously restores user sessions from local preferences on app launch to eliminate screen flicker.
- **Customer & Guest Support**: Supports existing WordPress/WooCommerce user accounts, quick guest checkout, and persistent login upon order completion.
- **Order Tracking & Details**: View past orders, delivery status, items, and billing details.

### 🎨 Seamless User Interface
- **Fixed Navigation**: Multi-tab navigation powered by `IndexedStack` to keep all tabs (`Home`, `Shop`, `Cart`, `Profile`, `Contact`, `About`) alive without reloading state or jumping the bottom bar.
- **Network & Connectivity Listener**: Built-in offline detection and automatic reconnect notifications.
- **Modern UI Components**: Custom toast notifications, responsive grids, and Google Fonts (Poppins).

---

## 🏗️ Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, SDK `^3.2.0`)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: `http` with RESTful WooCommerce Store API (`/wp-json/wc/store/v3/`) and WordPress REST API
- **Local Persistence**: `shared_preferences`
- **Network Status**: `connectivity_plus`
- **Typography & Styling**: `google_fonts` (Poppins)
- **External Links & Sharing**: `url_launcher`, `share_plus`

---

## 📂 Project Structure

```
kolkatafish_app/
├── android/                   # Android native configuration and Gradle files
├── assets/
│   └── images/                # App icons, banners, and placeholder graphics
├── lib/
│   ├── data/                  # Category lists, fallback catalogs, and seed data
│   │   ├── sea_categories.dart
│   │   └── seafood_data.dart
│   ├── models/                # Data models
│   │   └── sea_product.dart   # Product model with gross/net weights & specs
│   ├── providers/             # State management
│   │   ├── auth_provider.dart         # Persistent session & credentials
│   │   ├── cart_provider.dart         # Cart state, quantities & coupon discounts
│   │   └── connectivity_provider.dart # Live internet connection status
│   ├── screens/               # App views and pages
│   │   ├── home_screen.dart           # Root shell with persistent IndexedStack nav
│   │   ├── shop_tab.dart              # Product browsing & filter tabs
│   │   ├── product_detail_screen.dart # Detailed specs, net/gross wt, and add-to-cart
│   │   ├── search_screen.dart         # Live search & tags
│   │   ├── cart_tab.dart              # Cart overview, coupon input & offers
│   │   ├── checkout_screen.dart       # Address input & delivery slot selector
│   │   ├── payment_screen.dart        # Payment method selection & order placement
│   │   ├── order_confirmation_screen.dart
│   │   ├── order_details_screen.dart
│   │   ├── profile_tab.dart
│   │   ├── reset_password_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── policy_screen.dart
│   │   ├── contact_tab.dart
│   │   └── about_tab.dart
│   ├── services/              # API and backend integrations
│   │   ├── auth_service.dart          # WordPress REST & fallback auth
│   │   ├── store_api_service.dart     # WooCommerce Store API, slots & coupons
│   │   └── connectivity_service.dart  # Connectivity monitoring
│   ├── utils/                 # Utility helpers
│   │   └── toast_helper.dart
│   ├── widgets/               # Reusable UI widgets
│   │   ├── modern_toast.dart
│   │   ├── product_card.dart
│   │   ├── paged_product_grid.dart
│   │   ├── hero_banner.dart
│   │   ├── trust_badges.dart
│   │   └── connectivity_listener.dart
│   └── main.dart              # App entrypoint with pre-warmed preferences
├── pubspec.yaml               # Flutter package configuration & dependencies
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.2.0`)
- [Android Studio](https://developer.android.com/studio) / Android SDK (API 33+)
- A physical Android device or Android Emulator with Developer Options & USB Debugging enabled

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd kolkatafish_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify analyzer status:**
   ```bash
   flutter analyze
   ```

4. **Run on a connected device:**
   ```bash
   # List connected devices
   flutter devices

   # Run the app in debug mode
   flutter run
   ```

---

## 📦 Building for Release

### Android APK
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```
The output bundle will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🔗 Backend API Notes

- **Store Base URL**: `https://kolkatafish.com`
- **WooCommerce Store API**: `https://kolkatafish.com/wp-json/wc/store/v3/`
- **Delivery Slots**: Queries `/wp-admin/admin-ajax.php?action=kolkatafish_get_delivery_slots` with `date` (`YYYY-MM-DD`) and `pincode`.
- **Order Metadata**: Includes `add_delivery_date` (`dd/mm/yy`) and `add_delivery_time` (`hh:mm am/pm - hh:mm am/pm`) to ensure full synchronization with the WooCommerce order manager.

---

## 📄 License
All rights reserved © KolkataFish (https://kolkatafish.com).

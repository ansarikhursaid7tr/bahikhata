# BahiKhata

**Digital Ledger for Shop, Staff & Personal Records**

BahiKhata is a private Android app designed for shop owners to track staff production, calculate earnings based on item rates, manage payments/advances, and generate reports. Built with Flutter and Firebase.

## Features

- 🔐 **Secure Login** — Username/password authentication via Firebase
- 👥 **Staff Management** — Add, edit, activate/deactivate staff members
- 📦 **Item Types** — Flexible item type management (Coat, Pant, Shirt, etc.)
- 💰 **Monthly Rates** — Set item-wise rates per month with rate snapshots
- 📝 **Production Entries** — Record daily staff production with auto-calculated totals
- 💳 **Money Entries** — Track advances, payments, deductions, and bonuses
- 📊 **Daily Reports** — View daily production and payment summaries
- 📈 **Monthly Reports** — Staff-wise monthly breakdown with payable formula
- 📒 **Staff Ledger** — Running balance with full transaction history
- 📄 **PDF/CSV Export** — Export branded reports with organization logo
- 🔒 **Role-Based Access** — Owner, Manager, and Staff roles
- 📶 **Offline Support** — Firestore offline persistence with sync indicator
- 🏗️ **Future-Proof** — Extensible for any shop type or personal ledger

## Tech Stack

- **Flutter** 3.41+ (Android)
- **Firebase Authentication** (Email/Password)
- **Cloud Firestore** (Database)
- **Riverpod** (State Management)
- **GoRouter** (Navigation)
- **PDF + Printing** (Report export)

## Getting Started

### Prerequisites

- Flutter SDK 3.41+
- Android Studio or VS Code
- A Firebase project

### Setup

1. **Clone and install dependencies:**
   ```bash
   cd bahiKhata
   flutter pub get
   ```

2. **Set up Firebase:**
   Follow the detailed instructions in [firebase_setup.md](firebase_setup.md)

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build release APK:**
   ```bash
   flutter build apk --release
   ```
   APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Root widget
├── router.dart                  # GoRouter configuration
├── firebase_options.dart        # Firebase config (auto-generated)
├── models/                      # Data models
│   ├── enums.dart              # Shared enums (UserRole, BusinessType, etc.)
│   ├── organization_model.dart
│   ├── app_user_model.dart
│   ├── staff_model.dart
│   ├── item_type_model.dart
│   ├── monthly_rate_model.dart
│   ├── production_entry_model.dart
│   ├── production_item_model.dart
│   ├── money_entry_model.dart
│   └── audit_log_model.dart
├── services/                    # Business logic
│   ├── auth_service.dart       # Firebase Auth wrapper
│   ├── firestore_service.dart  # Firestore CRUD
│   ├── report_service.dart     # Report generation
│   └── export_service.dart     # PDF/CSV export
├── providers/                   # Riverpod providers
│   ├── auth_provider.dart
│   └── data_providers.dart
├── screens/                     # UI screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── staff/
│   ├── item_types/
│   ├── rates/
│   ├── production_entries/
│   ├── money_entries/
│   ├── reports/
│   ├── ledger/
│   └── settings/
├── widgets/                     # Reusable widgets
│   ├── summary_card.dart
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── loading_view.dart
│   ├── empty_state.dart
│   └── sync_indicator.dart
├── theme/
│   └── app_theme.dart          # App theme & colors
└── utils/
    ├── constants.dart
    ├── date_utils.dart
    ├── money_utils.dart
    └── validators.dart
```

## Firestore Structure

```
organizations/{organizationId}
├── users/{uid}
├── staff/{staffId}
├── itemTypes/{itemTypeId}
├── monthlyRates/{month_itemTypeId}
├── productionEntries/{entryId}
├── moneyEntries/{moneyEntryId}
└── auditLogs/{logId}
```

## User Roles

| Feature | Owner/Admin | Manager | Staff |
|---------|:-----------:|:-------:|:-----:|
| Manage Staff | ✅ | ❌ | ❌ |
| Manage Item Types | ✅ | ❌ | ❌ |
| Set Monthly Rates | ✅ | ❌ | ❌ |
| Add Production Entries | ✅ | ✅ | ❌ |
| Add Money Entries | ✅ | ✅ | ❌ |
| View All Reports | ✅ | ✅ | ❌ |
| View Own Data | ✅ | ✅ | ✅ |
| Export Reports | ✅ | ❌ | ❌ |
| Manage Settings | ✅ | ❌ | ❌ |

## Key Business Logic

**Monthly Payable Formula:**
```
Final Payable = Gross Production + Total Bonus
              - Total Advance - Total Partial Payment
              - Total Final Payment - Total Deduction
```

**Rate Snapshot:** When saving production entries, the current month's rate is stored as `rateSnapshot` in each line item. Old records are never recalculated when rates change.

## Login

The app uses username-based login. Internally, `username` is mapped to `username@bahikhata.local` for Firebase Auth. The UI shows only "Username" and "Password" fields.

## License

Private application. Not for redistribution.

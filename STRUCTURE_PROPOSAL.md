# Proposal Struktur Folder yang Lebih Terorganisir

## Struktur Saat Ini
```
lib/
├── pages/
│   ├── add_kos_page.dart          # Owner
│   ├── edit_kos_page.dart          # Owner
│   ├── manage_kos_page.dart        # Owner
│   ├── bookings_page.dart          # Society + Owner (view bookings)
│   ├── booking_detail_page.dart    # Society + Owner
│   ├── home_page.dart              # Shared (browsing)
│   ├── dashboard_page.dart         # Shared (navigation)
│   ├── profile_page.dart           # Shared
│   ├── login_page.dart             # Auth
│   ├── register_page.dart          # Auth
│   ├── forgot_password_page.dart    # Auth
│   ├── change_password_page.dart    # Auth
│   └── splash_page.dart            # Shared
```

## Struktur yang Disarankan
```
lib/
├── pages/
│   ├── auth/                       # Authentication pages
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── forgot_password_page.dart
│   │   └── change_password_page.dart
│   │
│   ├── owner/                      # Owner-specific pages
│   │   ├── add_kos_page.dart
│   │   ├── edit_kos_page.dart
│   │   └── manage_kos_page.dart
│   │
│   ├── society/                    # Society (penyewa) pages
│   │   ├── bookings_page.dart
│   │   └── booking_detail_page.dart
│   │
│   ├── shared/                     # Shared pages
│   │   ├── home_page.dart          # Browsing kos (all users)
│   │   ├── dashboard_page.dart     # Main navigation
│   │   ├── profile_page.dart       # User profile
│   │   └── splash_page.dart        # Splash screen
│   │
│   └── kos/                        # Kos-related pages (shared)
│       └── kos_detail_page.dart    # Detail page (extracted from home_page)
│
├── widgets/                        # Reusable widgets
│   ├── kos/
│   │   ├── kos_card.dart
│   │   ├── kos_list_item.dart
│   │   └── kos_image_carousel.dart
│   ├── common/
│   │   ├── custom_app_bar.dart
│   │   ├── bottom_nav_bar.dart
│   │   └── search_bar.dart
│   └── owner/
│       └── kos_form_fields.dart
│
├── models/                         # Data models (tetap sama)
├── services/                       # API services (tetap sama)
└── core/                           # Core utilities (tetap sama)
```

## Keuntungan Struktur Baru

1. **Lebih Terorganisir**: Pages dikelompokkan berdasarkan fungsi dan role
2. **Mudah Ditemukan**: Developer tahu langsung di mana mencari file
3. **Scalable**: Mudah menambah page baru di folder yang tepat
4. **Maintainable**: Perubahan di satu role tidak mempengaruhi role lain
5. **Widget Reusable**: Widget yang digunakan berulang dipisah ke folder widgets

## Catatan Penting

- `home_page.dart` saat ini sangat besar (3295 lines) dan berisi:
  - HomePage widget
  - KosDetailPage widget
  - Banyak helper widgets (_FeaturedCard, _ModernKosCard, dll)
  
  **Rekomendasi**: 
  - Extract `KosDetailPage` ke `pages/kos/kos_detail_page.dart`
  - Extract helper widgets ke `widgets/kos/` folder
  - Ini akan membuat code lebih maintainable

## Langkah Migrasi (Opsional)

Jika ingin melakukan refactoring:
1. Buat folder baru sesuai struktur
2. Pindahkan file secara bertahap
3. Update import statements
4. Test setiap perubahan

**Catatan**: Struktur saat ini masih bisa digunakan, tapi struktur baru akan lebih baik untuk jangka panjang.


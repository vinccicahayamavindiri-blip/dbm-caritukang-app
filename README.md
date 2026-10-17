# Dewa Bangun Mandiri (`dbm.caritukang.pro`) - Flutter App

Aplikasi mobile berbasis Flutter (Android & iOS) untuk **Dewa Bangun Mandiri (`https://dbm.caritukang.pro`)** lengkap dengan:
- **Splash Screen & App Icon** menggunakan logo resmi **Dewa Bangun Mandiri**.
- **Akses Kamera & Upload File/Foto** (`<input type="file" accept="image/*" capture>` & WebRTC `getUserMedia`) dari kamera langsung maupun galeri.
- **Akses GPS / Lokasi Akurat** (`navigator.geolocation` + pengecekan GPS aktif) untuk absensi dan pemetaan.
- **Unduh File & Link Eksternal** untuk membuka PDF/Excel/Gambar serta aplikasi eksternal seperti **WhatsApp (`wa.me` / `whatsapp://`)**, **Google Maps**, **Telepon (`tel:`)**, dan **Email (`mailto:`)**.
- **Pull-to-Refresh**, indikator loading atas, serta halaman penanganan jika koneksi terputus.

---

## Struktur Proyek
- `lib/main.dart` — Kode utama aplikasi (`SplashScreen`, `WebViewScreen`, izin Kamera/Lokasi, File Upload/Download, dan Deep Link eksternal).
- `assets/images/logo.png` — Logo resmi Dewa Bangun Mandiri.
- `android/app/src/main/AndroidManifest.xml` — Konfigurasi izin Android (`CAMERA`, `ACCESS_FINE_LOCATION`, `READ_MEDIA_IMAGES`, `FileProvider`, dan `<queries>` untuk kamera & aplikasi eksternal).
- `ios/Runner/Info.plist` — Konfigurasi izin iOS (`NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryUsageDescription`).
- `.github/workflows/build_apk.yml` — Workflow otomatis untuk mem-build file `.apk` di GitHub Actions tanpa perlu menginstal Android Studio di lokal.

---

## Cara Menjalankan & Build APK

### Opsi 1: Build di Komputer Lokal (Jika sudah terinstal Flutter SDK)
Jalankan perintah berikut di terminal pada folder proyek ini:

```powershell
# 1. Lengkapi file gradle wrapper bawaan Flutter (tanpa menimpa kode yang sudah dibuat)
flutter create . --project-name dbm_caritukang --org pro.caritukang

# 2. Unduh paket & generate icon aplikasi otomatis dari logo
flutter pub get
dart run flutter_launcher_icons

# 3. Build file APK Release
flutter build apk --release
```
File APK siap pakai akan tersedia di:
`build/app/outputs/flutter-apk/app-release.apk`

### Opsi 2: Build Otomatis via GitHub Actions (Tanpa Install Flutter/Android Studio)
1. Push folder `dbm_app` ini ke repositori GitHub Anda.
2. Buka tab **Actions** di GitHub -> jalankan workflow **Build Android APK & iOS**.
3. Unduh file `dbm-caritukang-release-apk` yang sudah jadi dari bagian **Artifacts**.

<p align="center">
  <img src="store_assets/app_icon_512.png" width="120" height="120" alt="PDF Master Tools">
</p>

<h1 align="center">PDF Master Tools</h1>

<p align="center">
  <strong>A privacy-first, offline PDF utility for Android</strong>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License">
  </a>
  <a href="https://github.com/maheshraikg/Pdf_Tools/stargazers">
    <img src="https://img.shields.io/github/stars/maheshraikg/Pdf_Tools?style=flat&color=yellow" alt="GitHub Stars">
  </a>
  <a href="https://github.com/maheshraikg/Pdf_Tools/forks">
    <img src="https://img.shields.io/github/forks/maheshraikg/Pdf_Tools?style=flat&color=blue" alt="GitHub Forks">
  </a>
  <a href="https://github.com/maheshraikg/Pdf_Tools/watchers">
    <img src="https://img.shields.io/github/watchers/maheshraikg/Pdf_Tools?style=flat&color=green" alt="GitHub Watchers">
  </a>
  <a href="https://github.com/maheshraikg/Pdf_Tools/issues">
    <img src="https://img.shields.io/github/issues/maheshraikg/Pdf_Tools?style=flat&color=red" alt="GitHub Issues">
  </a>
  <a href="https://github.com/maheshraikg/Pdf_Tools/releases">
    <img src="https://img.shields.io/github/v/release/maheshraikg/Pdf_Tools?include_prereleases" alt="Latest Release">
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Platform">
  <img src="https://img.shields.io/github/last-commit/maheshraikg/Pdf_Tools?style=flat&color=orange" alt="Last Commit">
  <a href="https://oosmetrics.com/repo/maheshraikg/Pdf_Tools">
    <img src="https://api.oosmetrics.com/api/v1/badge/achievement/ae7516ca-85f2-4c6f-a679-149537b637d8.svg" alt="oosmetrics">
  </a>
</p>

---

## 📱 Get it on Android

> Not yet published. Play Store and F-Droid links will be added here once this fork's own listing goes live.
>
> Offline · Privacy-first · No account required

---
## ✨ Features

### 📄 PDF Management
- **Merge PDFs** — Combine multiple PDF files into a single document
- **Split PDF** — Split into multiple files or specific page ranges
- **Compress PDF** — Reduce file size while maintaining quality
- **Reorder Pages** — Visual drag-and-drop page reordering
- **Rotate Pages** — Rotate specific pages or entire documents
- **Extract Pages** — Extract specific pages to create new PDFs
- **Delete Pages** — Remove unwanted pages

### 🔄 Conversion Tools
- **Images to PDF** — Create PDFs from gallery images
- **PDF to Images** — Convert PDF pages to high-quality images (JPG/PNG/WebP)
- **HTML to PDF** — Direct webpage to PDF conversion
- **Scan to PDF** — Camera-based document scanning with automatic edge detection

### ✏️ Editing & Annotation
- **Annotate** — Highlight, draw, and markup PDFs with custom Canvas layering
- **Sign PDF** — Add digital signatures to documents
- **Fill Forms** — Complete PDF forms on the go
- **Flatten PDF** — Make forms and annotations permanent

### 🔒 Privacy & Security
- **Lock PDF** — Password-protect your files
- **Unlock PDF** — Remove passwords (with valid password)
- **Watermark** — Add text or image watermarks
- **All processing on-device** — No cloud, no servers
- **No internet permission** — Completely offline capable
- **No data collection or tracking**

### 🔤 OCR & Text
- **Extract Text** — Pull text content from PDF pages
- **ML Kit OCR** — Play Store flavor (on-device, smaller APK)
- **Tesseract OCR** — F-Droid and opensource flavors (100% open source)

### 🖼️ Image Tools
- **Compress Images** — Optimize file sizes
- **Resize Images** — Change dimensions
- **Format Conversion** — JPG, PNG, WebP
- **Remove Metadata** — Strip EXIF data for privacy

---

## 🏗️ Build Flavors

| Flavor | OCR Engine | Ads | Firebase | Distribution |
|--------|-----------|-----|----------|--------------|
| `playstore` | ML Kit | No | No | Google Play |
| `fdroid` | Tesseract | No | No | F-Droid (pending) |
| `opensource` | Tesseract | No | No | GitHub Releases |

All flavors are **privacy-first** with no ads, no analytics, and no proprietary dependencies except ML Kit in the Play Store flavor.

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Language** | Kotlin 100% |
| **UI Framework** | Jetpack Compose (Material Design 3) |
| **Architecture** | MVVM + Clean Architecture |
| **PDF Processing** | PdfBox-Android, Android PdfRenderer |
| **Annotations** | Custom Canvas + BlendMode layering |
| **OCR (Play Store)** | Google ML Kit |
| **OCR (F-Droid / Opensource)** | Tesseract (tesseract4android) |
| **Camera** | CameraX |
| **Images** | Coil, Glide, uCrop |
| **Database** | Room |
| **Preferences** | DataStore |
| **Async** | Coroutines & Flow |
| **Build** | Gradle + KSP |

---

## 🚀 Getting Started

### Prerequisites
- Android Studio Hedgehog or newer
- JDK 17+
- Android SDK 26+

### Build

```bash
# Clone the repository
git clone https://github.com/maheshraikg/Pdf_Tools.git
cd Pdf_Tools

# Play Store flavor (ML Kit OCR)
./gradlew assemblePlaystoreRelease

# F-Droid flavor (Tesseract OCR, no proprietary deps)
./gradlew assembleFdroidRelease

# Opensource flavor (fully FOSS)
./gradlew assembleOpensourceRelease
```

---

## 📦 Download

| Platform | Link | Notes |
|----------|------|-------|
| Google Play | Not yet published | Will be added once this fork's Play Console listing is live |
| GitHub Releases | [Download APK](https://github.com/maheshraikg/Pdf_Tools/releases) | Opensource flavor, manual install |
| F-Droid | Not yet submitted | Will be added once submitted under this fork's package ID |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request against `master`

**Important:** The F-Droid and opensource flavors must remain free of proprietary dependencies. Any new dependencies must be compatible with the F-Droid inclusion policy.

See [open issues](https://github.com/maheshraikg/Pdf_Tools/issues) for feature requests and bug reports.

---

## 👤 Maintainer

**maheshraikg**  
GitHub: [@maheshraikg](https://github.com/maheshraikg)

This is a fork of the original [PDF Toolkit](https://github.com/Karna14314/Pdf_Tools) project, created by Narisetti Chaitanya Naidu and licensed under Apache 2.0.

---

## 📄 License

Copyright © 2024-2025 PDF Toolkit Contributors (original project)  
Modifications Copyright © 2026 maheshraikg

Licensed under the Apache License, Version 2.0  
See [LICENSE](LICENSE) for full text and [NOTICE](docs/NOTICE.md) for third-party attributions.

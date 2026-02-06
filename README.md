# USB File Manager

A robust Flutter application designed for seamless management of files on external USB drives. This project follows industry-standard architectural patterns and provides a professional user experience for file operations on Android devices.

## 🚀 Key Features

- **USB Detection**: Real-time monitoring and detection of connected USB devices.
- **File Browsing**: Explore directories and files within the connected USB storage.
- **Media Filtering**: List photos and videos with optional date range filtering (Start and End dates).
- **File Operations**: 
  - Multi-selection and "Select All" capabilities.
  - Download/Save selected USB files directly to the phone's internal storage.
- **Modern UI**: 
  - Adaptive Dark Mode support.
  - Professional progress indicators for file operations (Linear progress with detailed file status).
  - Integration with Storage Access Framework (SAF) for secure folder picking.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/) (Functional approach)
- **Functional Programming**: [fpdart](https://pub.dev/packages/fpdart)
- **Data Modeling**: [Equatable](https://pub.dev/packages/equatable) for value-based equality.
- **Storage**: Integration with Android's Storage Access Framework.

## 🏗️ Architecture

The project adheres to **Clean Architecture** principles, ensuring a separation of concerns and maintainability:

- **Presentation Layer**: UI widgets and Riverpod Providers for managing screen states.
- **Domain Layer**: Core business logic, Entities, and Use Case definitions.
- **Data Layer**: Repository implementations and data sources (USB access, local storage).

## 📥 Getting Started

### Prerequisites

- Flutter SDK (refer to `pubspec.yaml` for minimum version).
- Android device with USB OTG support.

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd file_viewer
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 📝 Analysis & Linting

The project uses `flutter_lints` to maintain code quality. Run analysis using:
```bash
flutter analyze
```

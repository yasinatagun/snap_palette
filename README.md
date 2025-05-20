# Snap Palette

A Flutter app that extracts color palettes from images. Take a photo or select an image from your gallery, and Snap Palette will analyze it to generate a beautiful color palette.

## Features

- 📸 Take photos with camera or select from gallery
- 🎨 Extract dominant colors from images
- 🔄 Save palettes to your collection
- 👀 View all your saved palettes
- 🔒 Firebase Authentication

## Setup

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart (2.16.0 or higher)
- Firebase account

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/snap_palette.git
   cd snap_palette
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Firebase:
   - Create a new Firebase project at [firebase.google.com](https://firebase.google.com)
   - Add Android and iOS apps to your Firebase project
   - Follow the instructions to download the configuration files
   - Create a `firebase_options.dart` file based on the template:
     ```
     cp lib/firebase_options.template.dart lib/firebase_options.dart
     ```
   - Replace the placeholder values in `firebase_options.dart` with your actual Firebase configuration

4. Run the app:
   ```
   flutter run
   ```

## Firebase Configuration

For security reasons, the Firebase configuration file is not included in the repository. You need to create your own Firebase project and configuration file:

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Enable Storage
5. Use Firebase CLI or Firebase console to download your configuration
6. Create `lib/firebase_options.dart` based on the template file, filling in your actual configuration values

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

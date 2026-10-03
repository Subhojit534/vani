# Vani — SIH26042

> **AI-Powered Vernacular Pedagogy and Real-Time Translation Tool for Mother Tongue-Based Primary Education**

Vani is a Flutter-based mobile application designed for the **Smart Education** category of Smart India Hackathon problem statement **SIH26042**. It helps Hindi-medium teachers deliver foundational literacy and numeracy (FLN) learning content in a tribal mother tongue, beginning with **Santali**.

The application provides a practical technology bridge between teachers and children in multilingual classrooms through translation, speech interaction, curriculum support, phrasebooks, and downloadable learning resources.

## Problem statement

Jharkhand's PALASH Mother Tongue-Based Multilingual Education (MTB-MLE) programme has shown the value of teaching young learners in a language they understand at home. However, many teachers posted in tribal-area schools are Hindi-medium trained and do not have sufficient proficiency or digital resources in languages such as Ho, Mundari, and Santali.

Vani addresses this challenge by enabling a non-native-speaking teacher to:

- Translate Hindi classroom content into a target tribal language.
- Use voice input and text-to-speech for interactive classroom communication.
- Access FLN-oriented curriculum material from a single mobile interface.
- Use common classroom phrases without prior language training.
- Work with saved content in low-connectivity environments after synchronisation.

## Prototype scope

The current prototype focuses on Hindi-to-Santali classroom assistance and provides the foundation for expanding to Ho and Mundari.

| SIH26042 requirement | Vani prototype support |
| --- | --- |
| Hindi-to-tribal-language translation | Hindi-to-Santali translation workflow |
| Real-time classroom dialogue | Conversation screen with speech input and spoken output |
| FLN curriculum assistance | FLN Hub for curriculum-oriented learning content |
| Bilingual classroom support | Translation, phrasebook, and history screens |
| Low-connectivity usage | Saved preferences, history, and locally available app content |
| Low-cost Android deployment | Flutter Android application suitable for an Android 9+ tablet build |

> **Prototype note:** Translation quality, speech latency, language coverage, and the extent of offline operation depend on the configured translation service, device hardware, and locally synchronised language resources. The application is intended as a demonstrator for SIH26042 and should be field-tested with teachers and native Santali speakers before production deployment.

## Features

- **Hindi ↔ Santali classroom translation** for short classroom instructions and learning content.
- **Voice-enabled interaction** using speech recognition and text-to-speech.
- **Conversation mode** for teacher–student dialogue support.
- **FLN Curriculum Hub** for organising foundational literacy and numeracy material.
- **Phrasebook** containing frequently used classroom expressions.
- **Translation history** for revisiting previously translated content.
- **Light and dark themes** for comfortable use in different classroom conditions.
- **PDF and printable resource support** for curriculum and worksheet workflows.
- **Android-first Flutter architecture** with scope for future Ho and Mundari language packs.

## Technology stack

- **Framework:** Flutter / Dart
- **Primary platform:** Android tablets and mobile devices
- **Speech input:** `speech_to_text`
- **Speech output:** `flutter_tts`
- **Networking:** `dio`
- **Local preferences and history:** `shared_preferences`
- **Document generation:** `pdf`, `printing`
- **File access:** `path_provider`
- **Translation integration:** local `translation_api` package

## Project structure

```text
lib/
├── main.dart                         # Application entry point and navigation
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart           # Translation home screen
│   │   ├── conversation_screen.dart   # Voice conversation workflow
│   │   ├── fln_curriculum_hub_screen.dart
│   │   ├── phrasebook_screen.dart
│   │   └── history_screen.dart
│   └── theme/                         # Light and dark application themes
translation_api/                       # Translation service package
android/                               # Android build configuration
pubspec.yaml                           # Flutter dependencies and metadata
```

## Requirements

- Flutter **3.0.0 or later**
- Dart SDK **3.0.0 or later**
- Android Studio or another Flutter-supported Android toolchain
- Android SDK with Android 9 / API 28 or later for target deployment
- A physical Android device or emulator
- Microphone permission for speech input
- Text-to-speech support on the target device

Check the local toolchain before building:

```bash
flutter doctor
```

## Run locally

1. Clone the repository:

   ```bash
   git clone https://github.com/Subhojit534/vani.git
   cd vani
   ```

2. Fetch Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Connect an Android device or start an emulator, then verify it is detected:

   ```bash
   flutter devices
   ```

4. Run the application:

   ```bash
   flutter run
   ```

5. Grant microphone and speech permissions when prompted. For the best demonstration experience, use a physical Android device with speech recognition and text-to-speech enabled.

## Build and deploy to Android

### Debug APK

Use a debug build for development and classroom testing:

```bash
flutter build apk --debug
```

The APK is generated under:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install it on a connected device with:

```bash
flutter install
```

### Release APK

Build an optimised release APK:

```bash
flutter build apk --release
```

The release APK is generated under:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For architecture-specific packages, use:

```bash
flutter build apk --release --split-per-abi
```

This produces APKs for supported Android ABIs, including `arm64-v8a`, `armeabi-v7a`, and `x86_64` where applicable.

### Production signing

For production or Play Store distribution, configure a private upload keystore and signing properties in the Android project. Do not commit keystores, passwords, or signing credentials to GitHub.

Recommended release checklist:

- Test on an Android 9+ low-cost tablet.
- Test microphone permissions and speech recognition with Hindi speech.
- Verify Santali text rendering and text-to-speech voice availability.
- Test with connectivity disabled after required content has been synchronised.
- Measure translation and voice-response latency on the target device.
- Build and verify a signed release APK before distribution.

## Offline and low-connectivity operation

The SIH26042 target environment includes schools with unreliable internet connectivity. The intended deployment flow is:

1. Install the APK while connected to the internet.
2. Synchronise the required translation data, curriculum content, and language resources.
3. Verify that the teacher can access saved content without a network connection.
4. Use translation, phrasebook, history, and curriculum features in the classroom.
5. Reconnect periodically to receive updated content and language resources.

The exact offline capabilities depend on the configured `translation_api` implementation and the resources bundled or cached by the deployment. Any production rollout should include a dedicated offline inference and content-synchronisation validation pass.

## Release links

- **Latest release:** [Vani 1.0.0+1](https://github.com/Subhojit534/vani/releases/tag/1.0.0%2B1)
- **All releases:** [GitHub Releases](https://github.com/Subhojit534/vani/releases)
- **Release APK assets:** [Download APKs from release 1.0.0+1](https://github.com/Subhojit534/vani/releases/tag/1.0.0%2B1)
- **Source repository:** [Subhojit534/vani](https://github.com/Subhojit534/vani)
- **SIH problem statement reference:** [SIH26042](https://www.sih.gov.in/)

The current release includes architecture-specific Android packages where available:

- `app-arm64-v8a-release.apk` — modern 64-bit Android devices
- `app-armeabi-v7a-release.apk` — compatible 32-bit ARM devices
- `app-x86_64-release.apk` — x86_64 Android environments and emulators

## Demo flow

A recommended SIH demonstration sequence is:

1. Open **Translate** and enter or speak a Hindi classroom instruction.
2. Display the Santali translation and play the spoken output.
3. Open **Conversation** and demonstrate interactive teacher–student dialogue.
4. Use **FLN Hub** to show curriculum-focused learning content.
5. Open **Phrasebook** for common classroom expressions.
6. Open **History** to revisit previously generated translations.
7. Disable connectivity and repeat the locally available workflow.

## Roadmap

- Add Ho and Mundari language packs.
- Improve native-speaker validation and contextual translation quality.
- Add fully offline speech recognition, translation, and text-to-speech models.
- Add NIPUN Bharat-aligned worksheet and visual flashcard generation.
- Add teacher accounts, content synchronisation, and school-level administration.
- Add classroom analytics while protecting student privacy.
- Benchmark sub-three-second voice interaction latency on target tablets.

## Contributing

Contributions are welcome, especially from Flutter developers, educators, linguists, and native speakers of Santali, Ho, Mundari, and Hindi.

1. Fork the repository.
2. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature
   ```

3. Make focused changes and add tests where appropriate.
4. Run formatting and analysis:

   ```bash
   dart format .
   flutter analyze
   flutter test
   ```

5. Open a pull request describing the educational use case, testing performed, and any language-data considerations.

## Privacy and responsible use

Vani is intended to assist teachers, not replace them. Translation and speech output should be reviewed by educators and native speakers before being used as authoritative learning material. Avoid storing personally identifiable student information, and obtain the required permissions before recording or processing voices in a classroom.

## License

See [LICENSE](LICENSE) for the terms applicable to this project.

## Team and project reference

- **Project:** Vani
- **Hackathon problem statement:** SIH26042
- **Category:** Software
- **Technology bucket:** Smart Education
- **Focus:** AI-assisted vernacular pedagogy, translation, speech interaction, and offline-first primary education

# Bolus Connect

A Flutter-based mobile application for diabetes management that helps users calculate insulin bolus doses based on their glucose levels, carbohydrate intake, and CGM trend arrows.

## Overview

Bolus Connect is an offline-first diabetes management tool designed to assist users in calculating insulin dosages. The app integrates with Firebase for authentication and uses OpenAI for AI-powered features, providing a comprehensive solution for insulin dose calculation with support for both Dexcom and Freestyle Libre CGM systems.

**IMPORTANT MEDICAL DISCLAIMER**: This application is for **educational use only**. All insulin dosing calculations should be reviewed and approved by your healthcare provider. Never use this app to make medical decisions without consulting your doctor.

## Key Features

### Insulin Bolus Calculator
- **Carbohydrate Coverage**: Calculate insulin doses based on carb intake and I:C ratio
- **Correction Bolus**: Adjust for current glucose vs. target glucose using ISF
- **CGM Trend Adjustment**: Factor in glucose trends using CGM arrows
  - Support for Dexcom (7 arrows: ↑↑ to ↓↓)
  - Support for Freestyle Libre (5 arrows: ↑ to ↓)
  - User-configurable trend adjustments
- **Dual Unit Support**: mg/dL and mmol/L glucose measurements
- **Precision Rounding**: Doses rounded to 0.1U for pump compatibility

### Health Profile & Personalized Tips
- **Health Questionnaire**: First-time setup to capture user health conditions and preferences
- **Time-Based Tips**: Personalized health tips based on selected conditions, delivered at appropriate times of day
  - Morning tips (4am-12pm)
  - Afternoon tips (12pm-6pm)
  - Evening tips (6pm-4am)
- **Intelligent Tip Rotation**: Avoids repeating tips and merges content from multiple conditions

### Bolus History & Analytics
- **Local Storage**: Up to 100 bolus calculations stored locally
- **Detailed Logs**: Track glucose, carbs, calculated doses, and personal notes
- **Insights Tab**: Review past calculations and identify patterns

### User Settings
- **Customizable Parameters**: Configure I:C ratio, target glucose, and ISF
- **CGM Manufacturer Selection**: Choose between Dexcom and Freestyle Libre
- **Trend Adjustment Settings**: Fine-tune arrow-based dose adjustments
- **Profile Management**: View and update health questionnaire responses

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Xcode (for iOS development)
- Android Studio (for Android development)
- Firebase project with authentication enabled

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd bolus_connect_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
```bash
flutterfire configure
```

4. Run the app:
```bash
flutter run
```

## Development Commands

### Running the App
```bash
# Run on connected device or simulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Building

#### iOS
```bash
# Build for iOS
flutter build ios

# Deploy to TestFlight (from ios/ directory)
cd ios && bundle exec fastlane ios beta
```

#### Android
```bash
# Build APK
flutter build apk

# Build App Bundle (for Play Store)
flutter build appbundle
```

### Testing & Code Quality
```bash
# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
flutter format lib/ test/
```

### Maintenance
```bash
# Update dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean
```

## Architecture

### Application Flow
1. **Authentication Gate**: Checks Firebase auth state and disclaimer acceptance
   - New users: Welcome → Disclaimer → Login
   - Returning users: Direct to main app
2. **Health Questionnaire**: First-time users complete health profile
3. **Main Navigation**: Four tabs for primary functionality
   - Home: Dashboard with personalized health tips
   - Insights: Bolus log history
   - Bolus: Insulin dose calculator
   - Settings: Profile and parameters

### Data Storage
- **SharedPreferences**: Bolus parameters, questionnaire answers, calculation logs
- **Flutter Secure Storage**: OpenAI API key (encrypted)
- **Firebase Auth**: User authentication and session management

### Key Services
- `BolusLogService`: Manages local storage of bolus calculations
- `HealthQuestionnaireService`: Stores and retrieves health profile data
- `HealthProfileSyncService`: Optional backend synchronization
- `TipBankService`: Manages personalized health tips based on user conditions
- `OpenAIClient`: API wrapper for AI-powered features

## Configuration

### Environment Variables
Set at compile time using `--dart-define`:

```bash
flutter run --dart-define=HEALTH_PROFILE_ENDPOINT=https://api.example.com/profile
```

Available variables:
- `HEALTH_PROFILE_ENDPOINT`: Backend URL for health profile synchronization

## Platform Support

- iOS (requires Xcode and provisioning profiles)
- Android (minimum SDK configured in build.gradle)
- Web (experimental)

## Security & Privacy

- All core functionality works offline
- User data stored locally on device
- Optional backend sync with authenticated endpoints
- Secure storage for API keys
- Firebase authentication for user management

## Contributing

For detailed development guidelines and architectural patterns, see [CLAUDE.md](CLAUDE.md).

## License

[Add your license information here]

## Support

For issues or questions, please [add contact information or issue tracker link].  
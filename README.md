<div align="center">

# 🏋️ FitAI

### Your AI-Powered Fitness Companion

*A full-featured Flutter fitness tracker with AI workout generation, real exercise data, and beautiful dark UI*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Groq AI](https://img.shields.io/badge/Groq_AI-Llama_3.3-F55036?style=for-the-badge)
![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-0175C2?style=for-the-badge)

</div>

---

## 📱 Screenshots

<div align="center">

### Onboarding & Auth
| Splash | Onboarding | Login | Sign Up |
|--------|-----------|-------|---------|
| ![Splash](screenshots/splash.png) | ![Onboarding](screenshots/onboarding.png) | ![Login](screenshots/login.png) | ![Signup](screenshots/signup.png) |

### Core Screens
| Home | Workouts | Workout Detail | Active Workout |
|------|----------|----------------|----------------|
| ![Home](screenshots/home.png) | ![Workouts](screenshots/workouts.png) | ![Detail](screenshots/workout_detail.png) | ![Active](screenshots/active_workout.png) |

### AI & Progress
| AI Coach | Rest Timer | Workout Complete | Progress |
|----------|-----------|-----------------|----------|
| ![AI Coach](screenshots/ai_coach.png) | ![Rest](screenshots/rest_timer.png) | ![Complete](screenshots/workout_complete.png) | ![Progress](screenshots/progress.png) |

### Profile
| Profile | Profile Setup |
|---------|--------------|
| ![Profile](screenshots/profile.png) | ![Setup](screenshots/profile_setup.png) |

</div>

---

## ✨ Features

### 🤖 AI-Powered
- **AI Workout Generator** — Generate personalized workout plans by muscle group and duration using Llama 3.3 70B via Groq
- **AI Coach Chat** — Real-time fitness coaching chatbot with conversation history
- **Smart Daily Suggestions** — Personalized daily workout recommendations based on your goals and fitness level

### 💪 Workout Tracking
- **Exercise Library** — 800+ exercises from the Wger fitness database with muscle group filtering
- **Active Workout Mode** — Live set/rep tracking with animated circular timer
- **Rest Timer** — Automatic 60-second rest countdown between sets with haptic feedback
- **Weight Tracking** — Per-exercise weight logging with +/− adjustments
- **Workout Complete** — Session summary with duration, calories, sets, and star rating

### 📊 Progress & Analytics
- **Weekly Charts** — Line chart showing workouts per week over 6 weeks
- **Calorie Charts** — Daily calorie burn bar chart for the current week
- **Personal Records** — Track your best lifts with trophy rankings
- **Streak Counter** — Consecutive day workout streak tracking

### 🔐 Authentication
- Email/password sign up and login
- Google Sign In
- Password reset via email
- Persistent sessions

### 🎨 UI/UX
- Dark theme only with purple (#6C63FF) accent
- Shimmer loading skeletons
- Pull-to-refresh on all data screens
- Offline support with Hive caching
- No-connection banner with cached data fallback
- Screen stays awake during active workouts

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── errors/          # AppException sealed class + mappers
│   ├── network/         # DioClient with logging + error interceptors
│   ├── routing/         # GoRouter configuration
│   ├── theme/           # Colors, text styles, ThemeData
│   └── utils/           # SnackBarHelper, DateFormatter, CalorieCalculator
├── data/
│   ├── models/          # UserProfile, Workout, Exercise, WorkoutSession, PersonalRecord
│   ├── repositories/    # AuthRepository, AiRepository
│   └── services/        # FirebaseService, WgerService, GeminiService (Groq)
└── presentation/
    ├── providers/        # Riverpod StateNotifier providers
    ├── screens/          # 16 screens
    └── widgets/          # Reusable widgets, charts, common components
```

### State Management
**Riverpod** with `StateNotifierProvider` for all mutable state. Each screen watches only what it needs — no unnecessary rebuilds.

### Error Handling
Sealed `AppException` class with typed subtypes (`NetworkException`, `TimeoutException`, `ServerException`, etc.). Every service layer maps raw library errors to typed exceptions before they reach the UI.

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.x |
| State Management | flutter_riverpod |
| Navigation | go_router |
| Backend | Firebase (Auth + Firestore + Storage) |
| AI | Groq API (Llama 3.3 70B) |
| Exercise Data | Wger REST API |
| Local Cache | Hive |
| HTTP Client | Dio (with interceptors) |
| Charts | fl_chart |
| Fonts | Google Fonts (Space Grotesk + Manrope) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code
- Firebase project
- Groq API key (free at [console.groq.com](https://console.groq.com))

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/fitai.git
cd fitai
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure Firebase**
- Create a project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable Authentication (Email/Password + Google)
- Create a Firestore database in test mode
- Download `google-services.json` → place in `android/app/`
- Add your debug SHA-1 fingerprint to Firebase (required for Google Sign In)

**4. Configure API keys**

Open `lib/core/constants/api_keys.dart`:
```dart
class ApiKeys {
  static const String groqApiKey = 'gsk_YOUR_GROQ_KEY_HERE';
  static const String wgerBaseUrl = 'https://wger.de/api/v2';
}
```

Get your free Groq key at [console.groq.com](https://console.groq.com) — no credit card required.

**5. Run the app**
```bash
flutter run
```

---

## 📋 Firestore Structure

```
users/{uid}/
  profile/main          → UserProfile document
  sessions/{sessionId}  → WorkoutSession documents
  records/{exerciseName}→ PersonalRecord documents
```

### Required Firestore Index
The progress screen requires one composite index. On first run, Firestore will log a link in the console — click it to auto-create the index (takes ~1 minute).

---

## 🔑 Environment Variables

| Key | Where to get it | Required |
|-----|----------------|----------|
| `groqApiKey` | [console.groq.com](https://console.groq.com) → Free | ✅ |
| `google-services.json` | Firebase Console → Project Settings | ✅ |
| SHA-1 fingerprint | `cd android && ./gradlew signingReport` | ✅ (Google Sign In) |

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1      # State management
  go_router: ^13.2.0            # Navigation
  firebase_core: ^2.27.1        # Firebase
  firebase_auth: ^4.17.9        # Authentication
  cloud_firestore: ^4.15.9      # Database
  dio: ^5.4.3                   # HTTP + Groq AI calls
  hive_flutter: ^1.1.0          # Offline cache
  fl_chart: ^0.67.0             # Charts
  shimmer: ^3.0.0               # Loading skeletons
  connectivity_plus: ^6.0.3     # Network status
  wakelock_plus: ^1.3.0         # Screen awake during workout
  google_fonts: ^6.2.1          # Typography
  google_sign_in: ^6.2.1        # Google auth
```

---

## 🎯 App Flow

```
Splash → Onboarding (first install)
       → Login / Sign Up
       → Profile Setup (first time)
       → Home
           ├── Workouts → Workout Detail → Active Workout → Workout Complete
           ├── AI Coach (Generate Plan + Chat)
           ├── Progress (Charts + Records)
           └── Profile (Settings + Logout)
```

---

## 📸 Adding Screenshots

To add screenshots to this README:
1. Create a `screenshots/` folder in the project root
2. Run the app and take screenshots on your device
3. Name them: `splash.png`, `onboarding.png`, `login.png`, `signup.png`, `home.png`, `workouts.png`, `workout_detail.png`, `active_workout.png`, `ai_coach.png`, `rest_timer.png`, `workout_complete.png`, `progress.png`, `profile.png`, `profile_setup.png`
4. The table above will automatically display them

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ using Flutter

*If this project helped you, please give it a ⭐*

</div>

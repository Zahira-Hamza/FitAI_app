$files = @(
    "lib/firebase_options.dart",
    "lib/core/constants/app_strings.dart",
    "lib/core/utils/calorie_calculator.dart",
    "lib/core/utils/date_formatter.dart",
    "lib/data/repositories/auth_repository.dart",
    "lib/data/repositories/workout_repository.dart",
    "lib/data/repositories/ai_repository.dart",
    "lib/data/services/wger_service.dart",
    "lib/data/services/gemini_service.dart",
    "lib/data/services/firebase_service.dart",
    "lib/presentation/screens/splash/splash_screen.dart",
    "lib/presentation/screens/onboarding/onboarding_screen.dart",
    "lib/presentation/screens/auth/login_screen.dart",
    "lib/presentation/screens/auth/signup_screen.dart",
    "lib/presentation/screens/auth/forgot_password_screen.dart",
    "lib/presentation/screens/profile_setup/profile_setup_screen.dart",
    "lib/presentation/screens/home/home_screen.dart",
    "lib/presentation/screens/workouts/workout_browser_screen.dart",
    "lib/presentation/screens/workouts/workout_detail_screen.dart",
    "lib/presentation/screens/active_workout/active_workout_screen.dart",
    "lib/presentation/screens/active_workout/rest_timer_screen.dart",
    "lib/presentation/screens/workout_complete/workout_complete_screen.dart",
    "lib/presentation/screens/ai_coach/ai_coach_screen.dart",
    "lib/presentation/screens/progress/progress_screen.dart",
    "lib/presentation/screens/profile/profile_screen.dart",
    "lib/presentation/widgets/common/stat_card.dart",
    "lib/presentation/widgets/common/bottom_nav_bar.dart",
    "lib/presentation/widgets/common/shimmer_loader.dart",
    "lib/presentation/widgets/workout/workout_card.dart",
    "lib/presentation/widgets/workout/exercise_list_tile.dart",
    "lib/presentation/widgets/workout/set_logger_row.dart",
    "lib/presentation/widgets/charts/weekly_line_chart.dart",
    "lib/presentation/widgets/charts/calories_bar_chart.dart",
    "lib/presentation/providers/auth_provider.dart",
    "lib/presentation/providers/user_profile_provider.dart",
    "lib/presentation/providers/workout_provider.dart",
    "lib/presentation/providers/active_workout_provider.dart",
    "lib/presentation/providers/ai_coach_provider.dart",
    "lib/presentation/providers/progress_provider.dart"
)

foreach ($f in $files) {
    if (-not (Test-Path $f)) {
        $dir = Split-Path -Path $f
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }
        $name = (Split-Path -LeafBase $f)
        $parts = $name.Split("_")
        $className = ""
        foreach ($p in $parts) {
            if ($p.Length -gt 0) {
                $className += $p.Substring(0,1).ToUpper() + $p.Substring(1)
            }
        }
        
        if ($f -match "screen") {
            $content = "import 'package:flutter/material.dart';`n`nclass $className extends StatelessWidget {`n  const ${className}({super.key});`n`n  @override`n  Widget build(BuildContext context) {`n    return const Scaffold(`n      body: Center(child: Text('$className')),`n    );`n  }`n}"
        } elseif ($f -match "widget|card|row|loader|nav_bar|chart|tile") {
            $content = "import 'package:flutter/material.dart';`n`nclass $className extends StatelessWidget {`n  const ${className}({super.key});`n`n  @override`n  Widget build(BuildContext context) {`n    return Container();`n  }`n}"
        } else {
            $content = "class $className {}"
        }
        
        Set-Content -Path $f -Value $content
    }
}

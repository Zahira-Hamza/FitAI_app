import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/common/fitai_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _age = 25;
  double _weight = 70;
  double _height = 170;
  String? _selectedGoal;
  String? _selectedLevel;

  static const _goals = [
    ('loseWeight', 'Lose Weight'),
    ('buildMuscle', 'Build Muscle'),
    ('stayActive', 'Stay Active'),
    ('improveEndurance', 'Improve Endurance'),
  ];

  static const _levels = [
    ('beginner', 'Beginner'),
    ('intermediate', 'Intermediate'),
    ('advanced', 'Advanced'),
  ];

  Future<void> _completeSetup() async {
    if (_selectedGoal == null || _selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your fitness goal and fitness level',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF252538),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final profile = UserProfile(
      uid: user.uid,
      name: user.displayName ?? 'Athlete',
      email: user.email ?? '',
      age: _age,
      weight: _weight,
      height: _height,
      goal: _selectedGoal!,
      level: _selectedLevel!,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(userProfileProvider.notifier).saveProfile(profile);
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save profile. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF252538),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Let's set up your profile",
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help us personalize your experience',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: Color(0xFF9E9EBE),
                ),
              ),
              const SizedBox(height: 32),

              // ── Age ──────────────────────────────────────────
              _SectionLabel(label: 'AGE'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleIconButton(
                    icon: Icons.remove,
                    onTap: () => setState(
                        () => _age = (_age - 1).clamp(13, 80)),
                  ),
                  const SizedBox(width: 32),
                  Text(
                    '$_age',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 32),
                  _CircleIconButton(
                    icon: Icons.add,
                    onTap: () => setState(
                        () => _age = (_age + 1).clamp(13, 80)),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Weight ───────────────────────────────────────
              _SectionLabel(label: 'WEIGHT'),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '40 – 150 kg',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: Color(0xFF5A5A7A),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF6C63FF),
                  inactiveTrackColor: const Color(0xFF252538),
                  thumbColor: const Color(0xFF6C63FF),
                  overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _weight,
                  min: 40,
                  max: 150,
                  divisions: 220,
                  onChanged: (v) => setState(() => _weight = v),
                ),
              ),
              const SizedBox(height: 20),

              // ── Height ───────────────────────────────────────
              _SectionLabel(label: 'HEIGHT'),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_height.toStringAsFixed(0)} cm',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '140 – 220 cm',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: Color(0xFF5A5A7A),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF6C63FF),
                  inactiveTrackColor: const Color(0xFF252538),
                  thumbColor: const Color(0xFF6C63FF),
                  overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _height,
                  min: 140,
                  max: 220,
                  divisions: 160,
                  onChanged: (v) => setState(() => _height = v),
                ),
              ),
              const SizedBox(height: 28),

              // ── Fitness Goal ─────────────────────────────────
              _SectionLabel(label: 'FITNESS GOAL'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _goals.map((g) {
                  final selected = _selectedGoal == g.$1;
                  return _PillButton(
                    label: g.$2,
                    selected: selected,
                    onTap: () => setState(() => _selectedGoal = g.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Fitness Level ────────────────────────────────
              _SectionLabel(label: 'FITNESS LEVEL'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _levels.map((l) {
                  final selected = _selectedLevel == l.$1;
                  return _PillButton(
                    label: l.$2,
                    selected: selected,
                    onTap: () => setState(() => _selectedLevel = l.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              FitAIButton(
                label: 'Complete Setup',
                isLoading: profileState.isLoading,
                onPressed: _completeSetup,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9E9EBE),
          letterSpacing: 1.2,
        ),
      );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C63FF)
                : const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF6C63FF).withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF9E9EBE),
            ),
          ),
        ),
      );
}

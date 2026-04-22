import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/fitai_button.dart';
import '../../widgets/common/fitai_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final progressState = ref.watch(progressProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + Name ────────────────────────────────
              _AvatarSection(
                profile: profile,
                onEditTap: () => _showEditSheet(context, ref, profile),
              ),
              const SizedBox(height: 24),

              // ── Stats ────────────────────────────────────────
              _StatsRow(progressState: progressState),
              const SizedBox(height: 20),

              // ── Goals ────────────────────────────────────────
              if (profile != null) ...[
                _GoalsCard(profile: profile, progressState: progressState),
                const SizedBox(height: 20),
              ],

              // ── Settings ─────────────────────────────────────
              const Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const _SettingsList(),
              const SizedBox(height: 24),

              // ── Log Out ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF6584)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6584),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 4),
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, UserProfile? profile) {
    final ctrl = TextEditingController(text: profile?.name ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF5A5A7A),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Edit Profile',
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Color(0xFF9E9EBE)),
                filled: true,
                fillColor: const Color(0xFF252538),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FitAIButton(
              label: 'Save Changes',
              onPressed: () async {
                if (profile == null) return;
                final updated = profile.copyWith(name: ctrl.text.trim());
                await ref
                    .read(userProfileProvider.notifier)
                    .updateProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?',
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontFamily: 'Manrope', color: Color(0xFF9E9EBE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9EBE))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Log Out',
                style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
  }
}

// ── Avatar Section ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onEditTap;
  const _AvatarSection({required this.profile, required this.onEditTap});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF6C63FF),
            backgroundImage: (profile?.avatarUrl.isNotEmpty ?? false)
                ? NetworkImage(profile!.avatarUrl)
                : null,
            child: (profile?.avatarUrl.isNotEmpty ?? false)
                ? null
                : Text(
                    (profile?.name.isNotEmpty == true)
                        ? profile!.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? 'Athlete',
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: Color(0xFF9E9EBE)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEditTap,
            child: const Text('Edit',
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC4C0FF))),
          ),
        ],
      );
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ProgressState progressState;
  const _StatsRow({required this.progressState});

  @override
  Widget build(BuildContext context) {
    final all = progressState.last6WeeksSessions;
    final totalHours = all.fold<int>(0, (s, e) => s + e.durationSeconds) / 3600;
    final streak = progressState.calculateStreak(all);

    return FitAICard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _StatItem(value: '${all.length}', label: 'Workouts'),
          _Vdivider(),
          _StatItem(value: totalHours.toStringAsFixed(1), label: 'Hours'),
          _Vdivider(),
          _StatItem(value: '$streak', label: 'Day Streak'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: Color(0xFF9E9EBE))),
          ],
        ),
      );
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: const Color(0xFF252538));
}

// ── Goals Card ────────────────────────────────────────────────────────────────

class _GoalsCard extends StatelessWidget {
  final UserProfile profile;
  final ProgressState progressState;
  const _GoalsCard({required this.profile, required this.progressState});

  static String _goalLabel(String g) {
    switch (g) {
      case 'loseWeight':
        return 'Lose Weight';
      case 'buildMuscle':
        return 'Build Muscle';
      case 'stayActive':
        return 'Stay Active';
      case 'improveEndurance':
        return 'Improve Endurance';
      default:
        return g;
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = progressState.weeklySessions.length;
    final progress = (count / 5).clamp(0.0, 1.0);

    return FitAICard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Goals',
                    style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(_goalLabel(profile.goal),
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: Color(0xFF9E9EBE))),
                const SizedBox(height: 8),
                Text('$count / 5 workouts this week',
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Color(0xFF43E97B))),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFF252538),
                  color: const Color(0xFF43E97B),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings ──────────────────────────────────────────────────────────────────

class _SettingsList extends ConsumerStatefulWidget {
  const _SettingsList();

  @override
  ConsumerState<_SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends ConsumerState<_SettingsList> {
  bool _notif = true;
  String _units = 'kg';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notif = p.getBool('notifications_enabled') ?? true;
      _units = p.getString('units') ?? 'kg';
    });
  }

  @override
  Widget build(BuildContext context) => FitAICard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Notifications',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              secondary: const Icon(Icons.notifications_outlined,
                  color: Color(0xFF9E9EBE)),
              value: _notif,
              activeColor: const Color(0xFF6C63FF),
              onChanged: (v) async {
                setState(() => _notif = v);
                final p = await SharedPreferences.getInstance();
                p.setBool('notifications_enabled', v);
              },
            ),
            _Hdivider(),
            ListTile(
              leading: const Icon(Icons.straighten, color: Color(0xFF9E9EBE)),
              title: const Text('Units',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_units,
                      style: const TextStyle(
                          fontFamily: 'Manrope', color: Color(0xFF9E9EBE))),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Color(0xFF5A5A7A)),
                ],
              ),
              onTap: () => _showUnitsSheet(context),
            ),
            _Hdivider(),
            SwitchListTile(
              title: const Text('Dark Mode',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              secondary: const Icon(Icons.dark_mode_outlined,
                  color: Color(0xFF9E9EBE)),
              value: true,
              activeColor: const Color(0xFF6C63FF),
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dark mode is the only way 🌙',
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Color(0xFF252538),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _Hdivider(),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF9E9EBE)),
              title: const Text('Help & Support',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              trailing:
                  const Icon(Icons.chevron_right, color: Color(0xFF5A5A7A)),
              onTap: () {},
            ),
          ],
        ),
      );

  void _showUnitsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF5A5A7A),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Units',
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            for (final u in ['kg', 'lbs'])
              RadioListTile<String>(
                value: u,
                groupValue: _units,
                title: Text(u,
                    style: const TextStyle(
                        fontFamily: 'Manrope', color: Colors.white)),
                activeColor: const Color(0xFF6C63FF),
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _units = v);
                  final p = await SharedPreferences.getInstance();
                  p.setString('units', v);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Hdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        color: Color(0xFF252538),
        indent: 16,
        endIndent: 16,
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'Koneksi'),
          _SettingsTile(
            icon: Icons.cloud_rounded,
            title: 'Provider AI',
            subtitle: 'Atur API key provider',
            onTap: () => context.go('/settings/keys'),
          ),
          _SettingsTile(
            icon: Icons.wifi_rounded,
            title: 'Hubungkan ke OpenCode',
            subtitle: 'Cari server OpenCode yang berjalan',
            onTap: () => context.go('/connect'),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Umum'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Tentang',
            subtitle: 'PocketVibe IDE v1.0.1',
            onTap: () => context.go('/settings/about'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(title, style: AppTextStyles.subtitle),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.title),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

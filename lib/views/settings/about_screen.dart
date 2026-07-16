import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang PocketVibe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.bolt_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('PocketVibe IDE', style: AppTextStyles.displayMedium),
            const SizedBox(height: 4),
            Text('v1.0.0', style: AppTextStyles.subtitle),
            const SizedBox(height: 32),
            const _InfoRow(label: 'Runtime', value: 'OpenCode via Termux'),
            const _InfoRow(label: 'Arsitektur', value: 'Companion Bridge'),
            const _InfoRow(label: 'Framework', value: 'Flutter + Kotlin'),
            const _InfoRow(label: 'Lisensi', value: 'MIT'),
            const Spacer(),
            Text(
              '100% lokal di device Anda.\nTidak ada data yang dikirim ke cloud.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.subtitle),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

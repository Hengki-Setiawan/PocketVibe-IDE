import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  _buildHowItWorksPage(),
                  _buildWhatYouNeedPage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.bolt_rounded, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('PocketVibe IDE', style: AppTextStyles.displayLarge),
          const SizedBox(height: 12),
          Text(
            'Asisten coding AI\n100% di HP-mu sendiri',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
              child: const Column(
              children: [
                _InfoRow(icon: Icons.phone_android_rounded, text: 'Berjalan penuh di perangkatmu'),
                SizedBox(height: 12),
                _InfoRow(icon: Icons.terminal_rounded, text: 'Ditenagai OpenCode AI'),
                SizedBox(height: 12),
                _InfoRow(icon: Icons.wifi_off_rounded, text: 'Tidak perlu internet terus-menerus'),
                SizedBox(height: 12),
                _InfoRow(icon: Icons.security_rounded, text: 'Data tidak keluar dari HP-mu'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bagaimana Cara Kerjanya?', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          const _StepCard(
            number: 1,
            title: 'Pasang "Mesin" AI-nya',
            desc: 'PocketVibe butuh Termux sebagai runtime Linux. Tenang, panduannya sudah disediakan langkah demi langkah.',
            icon: Icons.download_rounded,
          ),
          const SizedBox(height: 16),
          const _StepCard(
            number: 2,
            title: 'Buka Project',
            desc: 'Pilih folder coding-mu. Bisa bikin project baru atau buka yang sudah ada.',
            icon: Icons.folder_open_rounded,
          ),
          const SizedBox(height: 16),
          const _StepCard(
            number: 3,
            title: 'Chat dengan AI',
            desc: 'Tulis perintah, minta bantuan coding, atau suruh AI nulis kode. Semua diproses di HP-mu sendiri.',
            icon: Icons.chat_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouNeedPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Yang Kamu Butuhkan', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Hanya 3 langkah mudah', style: AppTextStyles.subtitle),
          const SizedBox(height: 32),
          const _NeedCard(
            icon: Icons.phone_android_rounded,
            title: '1. HP Android',
            desc: 'Minimal Android 10 (API 29). Semua HP modern support.',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const _NeedCard(
            icon: Icons.wifi_rounded,
            title: '2. Koneksi Internet',
            desc: 'Hanya sekali saat setup awal (download ~200MB). Setelah itu bisa offline.',
            color: AppColors.info,
          ),
          const SizedBox(height: 12),
          const _NeedCard(
            icon: Icons.key_rounded,
            title: '3. API Key AI',
            desc: 'Butuh kunci API dari Anthropic/OpenAI/OpenRouter (bisa daftar gratis).',
            color: AppColors.warning,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PocketVibe TIDAK perlu akses root. Semua berjalan aman di sandbox Android.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i ? AppColors.primary : AppColors.textMuted,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  context.go('/setup/guide');
                }
              },
              child: Text(_currentPage < 2 ? 'Lanjut' : 'Mulai Panduan Setup'),
            ),
          ),
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('Kembali'),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String desc;
  final IconData icon;
  const _StepCard({required this.number, required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('$number', style: AppTextStyles.headline.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _NeedCard({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                Text(desc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

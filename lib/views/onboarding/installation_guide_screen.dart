import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/termux_config.dart';
import '../../core/services/provider_manager.dart';
import '../../core/services/storage_permission_helper.dart';
import '../../providers/setup_provider.dart';
import '../../models/setup_step.dart';

enum _GuideStep {
  welcome,
  installTermux,
  installTermuxApi,
  runBootstrap,
  autoSetup,
  done,
}

class InstallationGuideScreen extends ConsumerStatefulWidget {
  const InstallationGuideScreen({super.key});

  @override
  ConsumerState<InstallationGuideScreen> createState() => _InstallationGuideScreenState();
}

class _InstallationGuideScreenState extends ConsumerState<InstallationGuideScreen> {
  _GuideStep _currentStep = _GuideStep.welcome;
  bool _termuxInstalled = false;
  bool _termuxApiInstalled = false;
  bool _checking = true;
  bool _bootstrapComplete = false;
  Timer? _bootstrapPollTimer;

  @override
  void initState() {
    super.initState();
    _checkInstallation();
  }

  @override
  void dispose() {
    _bootstrapPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInstallation() async {
    setState(() => _checking = true);
    final bridge = ref.read(termuxBridgeServiceProvider);
    final t = await bridge.isTermuxInstalled();
    final a = await bridge.isTermuxApiInstalled();
    if (mounted) {
      setState(() {
        _termuxInstalled = t;
        _termuxApiInstalled = a;
        _checking = false;
      });
    }
  }

  Future<void> _openFdroid(String packageName) async {
    final url = 'https://f-droid.org/packages/$packageName/';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Buka manual: $url')),
        );
      }
    }
  }

  void _copyBootstrapCommand() {
    Clipboard.setData(const ClipboardData(text: 'curl -sL ${TermuxConfig.bootstrapUrl} | bash'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perintah sudah disalin! Tempel di Termux.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startPollingBootstrap() {
    _bootstrapPollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      try {
        if (!await StoragePermissionHelper.hasFullStorageAccess()) {
          final needGrant = await StoragePermissionHelper.requestFullStorageAccess();
          if (needGrant && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Buka Settings → All files access → Allow, lalu kembali ke sini.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        final markerFile = io.File(TermuxConfig.readyMarkerFile);
        final ready = await markerFile.exists();
        if (ready) {
          t.cancel();
          if (mounted) {
            setState(() => _bootstrapComplete = true);
            _startAutoSetup();
          }
        }
      } catch (_) {}
    });

    Future.delayed(const Duration(minutes: 5), () {
      _bootstrapPollTimer?.cancel();
      if (mounted && !_bootstrapComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu habis. Pastikan kamu sudah menjalankan perintah di Termux.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _startAutoSetup() async {
    await ref.read(setupProvider.notifier).begin();
    if (mounted) {
      setState(() => _currentStep = _GuideStep.autoSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Setup'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case _GuideStep.welcome: return _buildWelcome();
      case _GuideStep.installTermux: return _buildInstallTermux();
      case _GuideStep.installTermuxApi: return _buildInstallTermuxApi();
      case _GuideStep.runBootstrap: return _buildBootstrapStep();
      case _GuideStep.autoSetup: return _buildAutoSetupProgress();
      case _GuideStep.done: return _buildDone();
    }
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Siapkan "Mesin" AI-mu', style: AppTextStyles.displayMedium),
          const SizedBox(height: 12),
          Text(
            'PocketVibe butuh beberapa komponen tambahan untuk bisa menjalankan AI di HP-mu. Ikuti 4 langkah mudah berikut:',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 32),
          const _GuideListItem(number: 1, title: 'Install Termux', desc: 'Runtime Linux on-device'),
          const SizedBox(height: 12),
          const _GuideListItem(number: 2, title: 'Install Termux:API', desc: 'Komunikasi antar aplikasi'),
          const SizedBox(height: 12),
          const _GuideListItem(number: 3, title: 'Jalankan 1 perintah', desc: 'Bootstrap otomatis (copy-paste)'),
          const SizedBox(height: 12),
          const _GuideListItem(number: 4, title: 'Tunggu setup selesai', desc: 'Otomatis, tinggal tunggu'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total ~5 menit. Koneksi internet hanya diperlukan saat setup awal.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = _GuideStep.installTermux),
              child: const Text('Mulai Panduan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallTermux() {
    return _InstallGuide(
      title: 'Langkah 1: Install Termux',
      icon: Icons.terminal_rounded,
      iconColor: AppColors.primary,
      installed: _termuxInstalled,
      checking: _checking,
      packageLabel: 'Termux',
      packageDesc: 'Runtime Linux yang menjalankan AI',
      fDroidPackage: 'com.termux',
      instructions: const [
        'Klik tombol "Buka F-Droid" di bawah',
        'Tap "Download APK" di halaman F-Droid',
        'Install APK yang sudah di-download',
        'Buka Termux sekali (cukup tunggu 5 detik)',
      ],
      warningText: 'Install dari F-Droid, BUKAN Google Play. Versi Play Store tidak support fitur yang dibutuhkan.',
      onInstall: () => _openFdroid('com.termux'),
      onCheckAgain: () async {
        await _checkInstallation();
        if (mounted && _termuxInstalled) {
          setState(() => _currentStep = _GuideStep.installTermuxApi);
        }
      },
      onSkip: () => setState(() => _currentStep = _GuideStep.installTermuxApi),
    );
  }

  Widget _buildInstallTermuxApi() {
    return _InstallGuide(
      title: 'Langkah 2: Install Termux:API',
      icon: Icons.api_rounded,
      iconColor: AppColors.accent,
      installed: _termuxApiInstalled,
      checking: _checking,
      packageLabel: 'Termux:API',
      packageDesc: 'Jembatan komunikasi antar-app',
      fDroidPackage: 'com.termux.api',
      instructions: const [
        'Klik tombol "Buka F-Droid" di bawah',
        'Tap "Download APK" di halaman F-Droid',
        'Install APK yang sudah di-download',
        'Setelah install, kembali ke sini',
      ],
      warningText: 'Termux:API diperlukan supaya PocketVibe bisa mengirim perintah ke Termux secara otomatis.',
      onInstall: () => _openFdroid('com.termux.api'),
      onCheckAgain: () async {
        await _checkInstallation();
        if (mounted && _termuxInstalled && _termuxApiInstalled) {
          setState(() => _currentStep = _GuideStep.runBootstrap);
        }
      },
      onSkip: () => setState(() => _currentStep = _GuideStep.runBootstrap),
    );
  }

  Widget _buildBootstrapStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Langkah 3 dari 4', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(height: 16),
          Text('Jalankan 1 Perintah di Termux', style: AppTextStyles.displayMedium),
          const SizedBox(height: 12),
          Text(
            'Copy perintah di bawah, buka aplikasi Termux, tempel (paste), lalu enter. Biarkan proses berjalan sampai selesai.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Termux', style: AppTextStyles.codeSmall.copyWith(color: AppColors.primary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: _copyBootstrapCommand,
                      style: IconButton.styleFrom(foregroundColor: AppColors.primary),
                      tooltip: 'Salin perintah',
                    ),
                  ],
                ),
                const Divider(height: 16),
                SelectableText(
                  'curl -sL ${TermuxConfig.bootstrapUrl} | bash',
                  style: AppTextStyles.code,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tips: Di Termux, paste dengan tap & tahan layar → "Paste". Proses bootstrap memakan waktu 1-3 menit.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded),
              onPressed: _copyBootstrapCommand,
              label: const Text('Salin Perintah'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.check_rounded),
              onPressed: () {
                setState(() => _currentStep = _GuideStep.autoSetup);
                ref.read(setupProvider.notifier).onBootstrapDone();
                _startPollingBootstrap();
              },
              label: const Text('Saya Sudah Menjalankannya'),
            ),
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentStep = _GuideStep.installTermuxApi),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSetupProgress() {
    final currentStep = ref.watch(setupProvider);

    ref.listen<SetupStep>(setupProvider, (_, step) {
      if (step == SetupStep.done) {
        setState(() => _currentStep = _GuideStep.done);
      }
    });

    final steps = [
      (SetupStep.installingOpenCode, 'Memasang OpenCode AI', 'Mengunduh dan menginstall OpenCode...'),
      (SetupStep.startingServer, 'Menyalakan Server', 'Memulai server OpenCode di background...'),
      (SetupStep.healthCheck, 'Memeriksa Koneksi', 'Memastikan server siap dipakai...'),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('Langkah 4 dari 4', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Menyiapkan Lingkungan AI', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text('Proses otomatis. Harap tunggu...', style: AppTextStyles.subtitle),
          const SizedBox(height: 32),
          if (currentStep == SetupStep.done)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80)
          else if (currentStep == SetupStep.failed)
            const Icon(Icons.error_rounded, color: AppColors.error, size: 80)
          else
            const SizedBox(
              width: 48, height: 48,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
          const SizedBox(height: 24),
          Text(
            currentStep.label,
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 32),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SetupStatusTile(
              label: s.$1,
              title: s.$2,
              desc: s.$3,
              isActive: currentStep == s.$1,
              isCompleted: _isStepCompleted(currentStep, s.$1),
              isFailed: currentStep == SetupStep.failed,
            ),
          )),
          if (currentStep == SetupStep.failed) ...[
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(setupProvider.notifier).reset();
                  setState(() => _currentStep = _GuideStep.runBootstrap);
                },
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isStepCompleted(SetupStep current, SetupStep step) {
    final order = [SetupStep.installingOpenCode, SetupStep.startingServer, SetupStep.healthCheck, SetupStep.done];
    final curIdx = order.indexOf(current);
    final stepIdx = order.indexOf(step);
    return curIdx > stepIdx;
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 100),
          const SizedBox(height: 24),
          Text('Setup Selesai! 🎉', style: AppTextStyles.displayLarge),
          const SizedBox(height: 12),
          Text(
            'PocketVibe IDE siap digunakan.\nKamu bisa mulai membuat project coding dan chat dengan AI.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 40),
          const _GuideTip(icon: Icons.folder_open_rounded, text: 'Buat project baru dari Dashboard'),
          const SizedBox(height: 12),
          const _GuideTip(icon: Icons.chat_rounded, text: 'Chat dengan AI di workspace'),
          const SizedBox(height: 12),
          const _GuideTip(icon: Icons.settings_rounded, text: 'Atur API key di menu Settings'),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Masuk ke Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallGuide extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool installed;
  final bool checking;
  final String packageLabel;
  final String packageDesc;
  final String fDroidPackage;
  final List<String> instructions;
  final String warningText;
  final VoidCallback onInstall;
  final VoidCallback onCheckAgain;
  final VoidCallback onSkip;

  const _InstallGuide({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.installed,
    required this.checking,
    required this.packageLabel,
    required this.packageDesc,
    required this.fDroidPackage,
    required this.instructions,
    required this.warningText,
    required this.onInstall,
    required this.onCheckAgain,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Langkah ${fDroidPackage == 'com.termux' ? '1' : '2'} dari 4',
              style: AppTextStyles.caption.copyWith(color: iconColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.displayMedium),
                    const SizedBox(height: 4),
                    Text(packageDesc, style: AppTextStyles.subtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (checking)
            const Center(child: CircularProgressIndicator())
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: installed ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    installed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: installed ? AppColors.success : AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installed ? '$packageLabel Terinstall' : '$packageLabel Belum Terinstall',
                          style: AppTextStyles.title.copyWith(
                            color: installed ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Cara Install:', style: AppTextStyles.title),
          const SizedBox(height: 12),
          ...instructions.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}', style: AppTextStyles.caption.copyWith(color: iconColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value, style: AppTextStyles.body)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(warningText, style: AppTextStyles.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: onInstall,
              label: const Text('Buka F-Droid'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(installed ? Icons.arrow_forward_rounded : Icons.refresh_rounded),
              onPressed: onCheckAgain,
              label: Text(installed ? 'Lanjut ke Langkah Berikutnya' : 'Cek Lagi'),
            ),
          ),
          if (!installed) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: onSkip,
                child: const Text('Lewati (sudah terinstall)'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Awal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideListItem extends StatelessWidget {
  final int number;
  final String title;
  final String desc;
  const _GuideListItem({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text('$number', style: AppTextStyles.title.copyWith(color: AppColors.primary)),
          ),
        ),
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
    );
  }
}

class _SetupStatusTile extends StatelessWidget {
  final SetupStep label;
  final String title;
  final String desc;
  final bool isActive;
  final bool isCompleted;
  final bool isFailed;

  const _SetupStatusTile({
    required this.label,
    required this.title,
    required this.desc,
    required this.isActive,
    required this.isCompleted,
    required this.isFailed,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Widget icon;
    if (isCompleted) {
      color = AppColors.success;
      icon = const Icon(Icons.check_circle_rounded, size: 24, color: AppColors.success);
    } else if (isActive) {
      color = AppColors.primary;
      icon = const SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
    } else if (isFailed) {
      color = AppColors.error;
      icon = const Icon(Icons.error_rounded, size: 24, color: AppColors.error);
    } else {
      color = AppColors.textMuted;
      icon = const Icon(Icons.circle_outlined, size: 24, color: AppColors.textMuted);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title.copyWith(color: color)),
                if (isActive) Text(desc, style: AppTextStyles.caption.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _GuideTip({required this.icon, required this.text});

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

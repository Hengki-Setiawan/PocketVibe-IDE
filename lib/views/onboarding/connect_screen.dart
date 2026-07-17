import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/provider_manager.dart';
import '../../models/connection_status.dart';
import '../../providers/connection_status_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final api = ref.read(openCodeApiClientProvider);
    try {
      if (await api.health()) {
        if (mounted) context.go('/dashboard');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectionStatusProvider);

    final isConnected = status.maybeWhen(
      data: (s) => s == ConnectionStatus.connected,
      orElse: () => false,
    );

    final icon = isConnected ? Icons.check_circle_rounded : Icons.terminal_rounded;
    final iconColor = isConnected ? AppColors.success : AppColors.primary;
    final title = isConnected ? 'Tersambung!' : 'Hubungkan ke OpenCode';

    String subtitle;
    if (isConnected) {
      subtitle = 'Server OpenCode berjalan. Klik lanjut.';
    } else if (status.maybeWhen(data: (s) => s == ConnectionStatus.checking, orElse: () => false)) {
      subtitle = 'Memeriksa koneksi...';
    } else if (status.maybeWhen(data: (s) => s == ConnectionStatus.disconnected, orElse: () => false)) {
      subtitle = 'Server tidak ditemukan.';
    } else {
      subtitle = 'Gagal memeriksa koneksi.';
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(icon, size: 80, color: iconColor),
              const SizedBox(height: 24),
              Text(title, style: AppTextStyles.displayMedium),
              const SizedBox(height: 12),
              Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
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
                        Text('Termux', style: AppTextStyles.title.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Buka Termux lalu jalankan:', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        'opencode serve --port 4096 --hostname 127.0.0.1',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tunggu sampai server berjalan, lalu tap "Coba Lagi"',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isConnected ? () => context.go('/dashboard') : _checkConnection,
                  child: Text(isConnected ? 'Masuk ke Dashboard' : 'Coba Lagi'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Lewati (tidak punya server)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

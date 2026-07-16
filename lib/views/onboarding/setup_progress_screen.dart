import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/setup_step.dart';
import '../../providers/setup_provider.dart';
import 'widgets/setup_step_tile.dart';

class SetupProgressScreen extends ConsumerStatefulWidget {
  const SetupProgressScreen({super.key});

  @override
  ConsumerState<SetupProgressScreen> createState() => _SetupProgressScreenState();
}

class _SetupProgressScreenState extends ConsumerState<SetupProgressScreen> {
  static const _steps = [
    SetupStep.installingOpenCode,
    SetupStep.startingServer,
    SetupStep.healthCheck,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final orchestrator = ref.read(setupProvider.notifier);
        if (!orchestrator.hasStarted) {
          await orchestrator.begin();
        }
      } catch (e) {
        debugPrint('SetupProgressScreen.initState begin() error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(setupProvider);

    ref.listen<SetupStep>(setupProvider, (_, step) {
      if (step == SetupStep.done) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Berjalan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            SizedBox(
              width: 120,
              height: 120,
              child: currentStep == SetupStep.done
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 120)
                  : currentStep == SetupStep.failed
                      ? const Icon(Icons.error_rounded, color: AppColors.error, size: 120)
                      : Lottie.asset(
                          'assets/lottie/setup_progress.json',
                          width: 120,
                          height: 120,
                        ),
            ),
            const SizedBox(height: 24),
            Text(
              currentStep.label,
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 8),
            Text(
              _getDescription(currentStep),
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 48),
            ..._steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SetupStepTile(
                step: step,
                isActive: currentStep == step && currentStep != SetupStep.failed,
                isCompleted: _isCompleted(currentStep, step),
                isFailed: currentStep == SetupStep.failed && !_isCompleted(currentStep, step),
              ),
            )),
            if (currentStep == SetupStep.failed) ...[
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(setupProvider.notifier).reset(),
                  child: const Text('Coba Lagi'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Lewati Setup'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isCompleted(SetupStep current, SetupStep step) {
    if (current == SetupStep.failed) return false;
    final order = [SetupStep.installingOpenCode, SetupStep.startingServer, SetupStep.healthCheck, SetupStep.done];
    final curIdx = order.indexOf(current);
    final stepIdx = order.indexOf(step);
    return curIdx > stepIdx;
  }

  String _getDescription(SetupStep step) {
    switch (step) {
      case SetupStep.installingOpenCode: return 'Memasang OpenCode AI di lingkungan Termux...';
      case SetupStep.startingServer: return 'Menyalakan server OpenCode...';
      case SetupStep.healthCheck: return 'Memeriksa koneksi ke server...';
      case SetupStep.done: return 'PocketVibe siap digunakan!';
      case SetupStep.failed: return 'Terjadi kesalahan. Coba lagi.';
      default: return '';
    }
  }
}

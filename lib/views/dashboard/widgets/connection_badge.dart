import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/connection_status.dart';

class ConnectionBadge extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: statusLabel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dotColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dotColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(statusLabel, style: AppTextStyles.caption.copyWith(color: dotColor)),
            ],
          ),
        ),
      ),
    );
  }

  Color get dotColor {
    switch (status) {
      case ConnectionStatus.connected: return AppColors.connected;
      case ConnectionStatus.disconnected: return AppColors.disconnected;
      case ConnectionStatus.checking: return AppColors.warning;
      case ConnectionStatus.error: return AppColors.serverError;
    }
  }

  String get statusLabel {
    switch (status) {
      case ConnectionStatus.connected: return 'Server Aktif';
      case ConnectionStatus.disconnected: return 'Server Mati';
      case ConnectionStatus.checking: return 'Memeriksa...';
      case ConnectionStatus.error: return 'Error';
    }
  }
}

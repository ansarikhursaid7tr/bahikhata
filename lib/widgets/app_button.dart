import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable app button with variants.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: width,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          width: width,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case AppButtonVariant.danger:
        return SizedBox(
          width: width,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.accent:
        return SizedBox(
          width: width,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            child: child,
          ),
        );
    }
  }
}

enum AppButtonVariant { primary, secondary, danger, accent }

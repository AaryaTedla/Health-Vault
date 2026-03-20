import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

// ─── Gradient Header ──────────────────────────────────────────────────────────
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;

  const GradientHeader({
    super.key, required this.title, this.subtitle,
    this.actions, this.leading, this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFF2980B9)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Big Accessible Button ────────────────────────────────────────────────────
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;

  const BigButton({
    super.key, required this.label, this.onTap,
    this.color, this.textColor, this.icon,
    this.isLoading = false, this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primary;
    return SizedBox(
      width: double.infinity, height: 60,
      child: Material(
        color: isOutlined ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onTap,
          child: Container(
            decoration: isOutlined ? BoxDecoration(
              border: Border.all(color: bg, width: 2),
              borderRadius: BorderRadius.circular(16),
            ) : null,
            child: Center(
              child: isLoading
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: isOutlined ? bg : (textColor ?? Colors.white), size: 22),
                        const SizedBox(width: 10),
                      ],
                      Text(label, style: TextStyle(
                        color: isOutlined ? bg : (textColor ?? Colors.white),
                        fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.3,
                      )),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Health Card ──────────────────────────────────────────────────────────────
class HealthCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets? padding;
  final double borderRadius;

  const HealthCard({
    super.key, required this.child, this.onTap,
    this.color, this.padding, this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppTheme.divider, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(
                fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ─── Loading Shimmer Card ─────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.2.seconds, color: Colors.white54);
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const StatChip({super.key, required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: TextStyle(
                fontSize: 11, color: color.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Disclaimer Box ───────────────────────────────────────────────────────────
class DisclaimerBox extends StatelessWidget {
  final String text;
  const DisclaimerBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(
            fontSize: 13, color: AppTheme.textSecondary, height: 1.5))),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key, required this.icon, required this.title,
    required this.subtitle, this.buttonLabel, this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(
              fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
              textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: BigButton(label: buttonLabel!, onTap: onButton),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}

// ─── Custom TextField ─────────────────────────────────────────────────────────
class HealthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;

  const HealthTextField({
    super.key, required this.label, this.hint, this.controller,
    this.keyboardType, this.obscureText = false,
    this.prefix, this.suffix, this.validator,
    this.onChanged, this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: prefix, suffixIcon: suffix,
      ),
    );
  }
}

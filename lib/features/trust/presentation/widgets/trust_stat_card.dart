// lib/features/trust/presentation/widgets/trust_stat_card.dart
import 'package:flutter/material.dart';

/// Mini stat card dùng trong Trust Dashboard
class TrustStatCard extends StatelessWidget {
  const TrustStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1C2C58),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : const Color(0xFF344267),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

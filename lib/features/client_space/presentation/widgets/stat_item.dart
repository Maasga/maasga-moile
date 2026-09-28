import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design_tokens/maasga_tokens.dart';

class StatItem extends StatelessWidget {
  const StatItem({
    required this.icon,
    required this.count,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: palette.accent),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: palette.accent,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

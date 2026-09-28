import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.card,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: palette.cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? palette.onAccent : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

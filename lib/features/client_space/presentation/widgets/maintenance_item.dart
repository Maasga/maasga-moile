import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design_tokens/maasga_tokens.dart';

class MaintenanceItem extends StatelessWidget {
  const MaintenanceItem({
    required this.date,
    required this.technicianName,
    required this.isCompleted,
    super.key,
  });

  final String date;
  final String technicianName;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final accent = isCompleted ? palette.success : palette.warning;
    final surface = isCompleted
        ? palette.successSurface
        : palette.warningSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending_outlined,
            size: 20,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'Tech: $technicianName',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isCompleted ? 'Effectuée' : 'À venir',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

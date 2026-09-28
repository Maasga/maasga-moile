import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design_tokens/maasga_tokens.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;

  const StepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(context, 0, 'Type'),
          _buildConnector(context, 1),
          _buildStep(context, 1, 'Détails'),
          _buildConnector(context, 2),
          _buildStep(context, 2, 'Confirmation'),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int step, String label) {
    final palette = context.maasga;
    final bool isActiveIndex = currentStep == step;
    final bool isPassed = currentStep > step;
    final bool isActive = isActiveIndex || isPassed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? palette.accent : palette.cardAlt,
          ),
          alignment: Alignment.center,
          child: Text(
            '${step + 1}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? palette.onAccent : palette.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: isActiveIndex ? FontWeight.w600 : FontWeight.w400,
            color: isActiveIndex ? palette.accent : palette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(BuildContext context, int nextStep) {
    final palette = context.maasga;
    final bool isPassed = currentStep >= nextStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          height: 2,
          color: isPassed ? palette.accent : palette.divider,
        ),
      ),
    );
  }
}

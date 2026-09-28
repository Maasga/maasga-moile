import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormulaCard extends StatelessWidget {
  final String title;
  final String? badgeText;
  final String? unitRateText;
  final String? targetRange;
  final String? frequencyTag;
  final String price;
  final String period;
  final String subtitle;
  final String economy;
  final List<String> inclusions;
  final String target;
  final String? bonusTitle;
  final String? bonusDesc;
  final String? customDescription;
  final String ctaText;
  final bool isRecommended;
  final bool isPremium;
  final bool isCustom;
  final bool isHighlighted;
  final VoidCallback onSelect;

  const FormulaCard({
    super.key,
    required this.title,
    this.badgeText,
    this.unitRateText,
    this.targetRange,
    this.frequencyTag,
    required this.price,
    this.period = '/ an',
    required this.subtitle,
    this.economy = '',
    this.inclusions = const [],
    required this.target,
    this.bonusTitle,
    this.bonusDesc,
    this.customDescription,
    this.ctaText = 'Choisir cette formule',
    this.isRecommended = false,
    this.isPremium = false,
    this.isCustom = false,
    this.isHighlighted = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B3A8D);
    final isDark = isPremium && !isCustom;
    final backgroundColor = isDark ? primaryColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF757575);

    Color borderColor;
    if (isHighlighted) {
      borderColor = const Color(0xFFFF6F00);
    } else if (isRecommended) {
      borderColor = primaryColor;
    } else if (isDark) {
      borderColor = Colors.transparent;
    } else {
      borderColor = const Color(0xFFE0E0E0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: (isHighlighted || isRecommended) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFFF6F00).withValues(alpha: 0.18)
                : (isRecommended
                    ? primaryColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05)),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (badgeText != null && badgeText!.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFFFD700)
                      : (isRecommended ? primaryColor : const Color(0xFFE65100)),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  badgeText!,
                  style: GoogleFonts.poppins(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : (isRecommended
                                      ? primaryColor
                                      : const Color(0xFF616161)),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (targetRange != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    targetRange!,
                                    style: GoogleFonts.poppins(
                                      color: isDark
                                          ? Colors.white
                                          : primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (unitRateText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    unitRateText!,
                                    style: GoogleFonts.poppins(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : const Color(0xFF616161),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (price.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  price,
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: price.length > 8 ? 22 : 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (period.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    ' F CFA $period',
                                    style: GoogleFonts.poppins(
                                      color: secondaryTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : const Color(0xFF757575),
                                fontSize: 12,
                              ),
                            ),
                          if (frequencyTag != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Fréquence : $frequencyTag',
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : const Color(0xFF858585),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (economy.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                economy,
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF43A047),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : (isRecommended
                                ? const Color(0xFFE8EEFF)
                                : const Color(0xFFF5F5F5)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCustom
                            ? Icons.handshake_outlined
                            : (isDark
                                ? Icons.factory_outlined
                                : (isRecommended
                                    ? Icons.business_outlined
                                    : Icons.home_outlined)),
                        color: isDark
                            ? Colors.white
                            : (isRecommended
                                ? primaryColor
                                : const Color(0xFF757575)),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF0F0F0),
                ),
                const SizedBox(height: 10),

                // Description personnalisée pour Sur Mesure
                if (customDescription != null) ...[
                  Text(
                    customDescription!,
                    style: GoogleFonts.poppins(
                      color: secondaryTextColor,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Inclusions
                if (inclusions.isNotEmpty) ...[
                  Text(
                    'Ce qui est inclus :',
                    style: GoogleFonts.poppins(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...inclusions.map(
                    (item) => _BulletItem(text: item, isDark: isDark),
                  ),
                  const SizedBox(height: 10),
                ],

                // Bonus
                if (bonusTitle != null && bonusDesc != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bonusTitle!,
                          style: GoogleFonts.poppins(
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : const Color(0xFFFB8C00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bonusDesc!,
                          style: GoogleFonts.poppins(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF757575),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (target.isNotEmpty)
                  Text(
                    target,
                    style: GoogleFonts.poppins(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.65)
                          : const Color(0xFF9E9E9E),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white
                          : (isRecommended
                              ? primaryColor
                              : (isCustom
                                  ? const Color(0xFF263238)
                                  : const Color(0xFFF0F3FA))),
                      foregroundColor: isDark
                          ? primaryColor
                          : (isRecommended || isCustom
                              ? Colors.white
                              : primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      ctaText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _BulletItem({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: isDark
                ? const Color(0xFFFFD700)
                : const Color(0xFF43A047),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

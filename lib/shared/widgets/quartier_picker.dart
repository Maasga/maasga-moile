import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/rdv/domain/neighborhoods.dart';
import '../design_tokens/maasga_tokens.dart';

class QuartierSearchBottomSheet extends StatefulWidget {
  const QuartierSearchBottomSheet({
    super.key,
    required this.onSelected,
    this.currentSelection,
  });

  final String? currentSelection;
  final void Function(String) onSelected;

  @override
  State<QuartierSearchBottomSheet> createState() =>
      _QuartierSearchBottomSheetState();
}

class _QuartierSearchBottomSheetState
    extends State<QuartierSearchBottomSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final filtered = ouagaNeighborhoods
        .where((q) => q.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: palette.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choisir un quartier',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(fontSize: 14, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un quartier...',
              hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: palette.textMuted),
              filled: true,
              fillColor: palette.cardAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: palette.divider,
              ),
              itemBuilder: (context, index) {
                final q = filtered[index];
                final isSelected = q == widget.currentSelection;
                return ListTile(
                  title: Text(
                    q,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isSelected ? palette.accent : palette.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: palette.accent)
                      : null,
                  onTap: () => widget.onSelected(q),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

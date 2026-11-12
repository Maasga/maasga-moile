class VisiteContrat {
  VisiteContrat({
    required this.date,
    required this.technicianName,
    required this.isCompleted,
    this.description,
    this.actions,
  });

  final String date;
  final String technicianName;
  final bool isCompleted;
  final String? description;
  final String? actions;

  factory VisiteContrat.fromJson(Map<String, dynamic> json) {
    return VisiteContrat(
      date: json['visit_date'] ?? json['date'] ?? '',
      technicianName: json['technician'] ?? json['technician_name'] ?? 'Technicien MAASGA',
      isCompleted: json['status'] == 'effectuee' || json['is_completed'] == true,
      description: json['description'] as String?,
      actions: json['actions_performed'] as String?,
    );
  }
}

class ContratMaintenance {
  ContratMaintenance({
    required this.id,
    required this.type,
    required this.period,
    required this.price,
    required this.status,
    required this.visites,
    required this.visitesEffectuees,
    required this.visitesTotales,
    required this.quartier,
    required this.planType,
    this.invoiceUrl,
    this.nbClimatiseurs,
    this.frequenceVisites,
    this.typeEtablissement,
    this.equipmentType,
    this.description,
    this.preferredDate,
    this.nextVisitDate,
    this.startDate,
    this.endDate,
    this.planPrice,
    this.orderId,
  });

  final String id;
  final String type;
  final String period;
  final String price;
  final String status;
  final List<VisiteContrat> visites;
  final int visitesEffectuees;
  final int visitesTotales;
  final String quartier;
  final String planType;
  final String? invoiceUrl;

  // Champs enrichis
  final int? nbClimatiseurs;
  final String? frequenceVisites;
  final String? typeEtablissement;
  final String? equipmentType;
  final String? description;
  final String? preferredDate;
  final String? nextVisitDate;
  final String? startDate;
  final String? endDate;
  final int? planPrice;
  final String? orderId;

  bool get isPending {
    final s = status.toLowerCase();
    return s == 'pending' || s.contains('attente');
  }

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'actif' || s == 'active';
  }

  factory ContratMaintenance.fromJson(Map<String, dynamic> json) {
    final visitesList =
        (json['visites'] as List<dynamic>?)
            ?.map((v) => VisiteContrat.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    int? safeInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
      return null;
    }

    // Formatter le prix
    String formatPrice(dynamic raw) {
      if (raw == null) return '0 FCFA';
      final val = safeInt(raw) ?? 0;
      if (val == 0) return json['price'] as String? ?? '0 FCFA';
      final s = val.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
      return '$s FCFA';
    }

    // Calculer la période depuis start_date/end_date
    String buildPeriod() {
      final start = json['start_date'] as String?;
      final end = json['end_date'] as String?;
      if (start != null && end != null) {
        try {
          final s = DateTime.parse(start);
          final e = DateTime.parse(end);
          final months = ['Jan', 'Fév', 'Mars', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
          return '${months[s.month - 1]} ${s.year} — ${months[e.month - 1]} ${e.year}';
        } catch (_) {}
      }
      return json['period'] as String? ?? '';
    }

    // Résoudre le type lisible
    String resolveType() {
      final pt = (json['plan_type'] as String? ?? '').toLowerCase();
      final rt = (json['request_type'] as String? ?? '').toLowerCase();
      if (pt.contains('semestriel') || rt.contains('semestriel')) return 'Semestriel (2 visites/an)';
      if (pt.contains('trimestriel') || rt.contains('trimestriel')) return 'Trimestriel (4 visites/an)';
      if (pt.contains('annuel') || rt.contains('annuel')) return 'Annuel (1 visite/an)';
      if (pt.contains('mensuel') || rt.contains('mensuel')) return 'Mensuel (12 visites/an)';
      if (json['type'] != null && (json['type'] as String).isNotEmpty) return json['type'] as String;
      return 'Contrat de maintenance';
    }

    return ContratMaintenance(
      id: json['id']?.toString() ?? '',
      type: resolveType(),
      period: buildPeriod(),
      price: formatPrice(json['plan_price'] ?? json['price']),
      status: json['status'] as String? ?? 'En attente',
      visites: visitesList,
      visitesEffectuees: safeInt(json['completed_visits'] ?? json['visites_effectuees']) ?? 0,
      visitesTotales: safeInt(json['total_visits'] ?? json['visites_totales']) ?? 1,
      quartier: json['quartier'] as String? ?? 'Ouagadougou',
      planType: json['plan_type'] as String? ?? '',
      invoiceUrl: json['invoice_url'] as String?,
      nbClimatiseurs: safeInt(json['nb_climatiseurs']),
      frequenceVisites: json['frequence_visites'] as String?,
      typeEtablissement: json['type_etablissement'] as String?,
      equipmentType: json['equipment_type'] as String?,
      description: json['description'] as String?,
      preferredDate: json['preferred_date'] as String?,
      nextVisitDate: json['next_visit_date'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      planPrice: safeInt(json['plan_price']),
      orderId: json['order_id']?.toString(),
    );
  }
}
/// Coordonnées officielles de MAASGA.
/// Toute l'application référence ce fichier — une seule modification
/// ici se propage partout.
class MaasgaContact {
  MaasgaContact._();

  // ── Identité ───────────────────────────────────────────────────────
  static const String companyName = 'MAASGA SARL';
  static const String activity = 'Froid & Climatisation';
  static const String city = 'Ouagadougou, Burkina Faso';

  // ── Téléphone ──────────────────────────────────────────────────────
  /// Numéro local (sans indicatif)
  static const String phoneLocal = '55996418';

  /// Numéro international complet (avec indicatif Burkina)
  static const String phoneInternational = '+22655996418';

  /// Numéro international sans le "+" (pour les URLs wa.me)
  static const String phoneE164 = '22655996418';

  // ── E-mail ─────────────────────────────────────────────────────────
  static const String email = 'maasgabf@gmail.com';

  // ── WhatsApp ───────────────────────────────────────────────────────
  /// Lien direct vers le profil WhatsApp MAASGA
  static const String whatsAppDirectLink =
      'https://wa.me/message/QHTL462Z2XT4K1';

  /// URL wa.me classique avec numéro (utilisée pour les messages pré-remplis)
  static const String whatsAppBaseUrl = 'https://wa.me/$phoneE164';

  // ── Messages WhatsApp pré-remplis ──────────────────────────────────
  static const String whatsAppMsgCommande =
      'Bonjour MAASGA, je viens de passer une commande et je souhaite finaliser le processus.';

  static const String whatsAppMsgSupport =
      'Bonjour MAASGA, j\'ai besoin d\'assistance.';

  static const String whatsAppMsgRdv =
      'Bonjour MAASGA, je viens d\'envoyer une demande de rendez-vous.';

  // ── Informations légales / PDF ─────────────────────────────────────
  // Vides par défaut, VOLONTAIREMENT : un devis ou une facture ne doit jamais
  // porter un identifiant légal inventé. Les documents omettent la ligne quand
  // la valeur est vide (cf. pdf_service). Renseigner au build :
  //   flutter build apk --release \
  //     --dart-define=MAASGA_RCCM=BF-OUA-XXXX-X-XXXX \
  //     --dart-define=MAASGA_IFU=XXXXXXXXX

  /// Numéro RCCM officiel de l'entreprise.
  static const String rccm = String.fromEnvironment('MAASGA_RCCM');

  /// Numéro IFU officiel de l'entreprise.
  static const String ifu = String.fromEnvironment('MAASGA_IFU');

  // ── Helpers URL ────────────────────────────────────────────────────
  /// Construit une URL wa.me avec message pré-rempli
  static String whatsAppUrl(String message) {
    final encoded = Uri.encodeComponent(message);
    return '$whatsAppBaseUrl?text=$encoded';
  }
}

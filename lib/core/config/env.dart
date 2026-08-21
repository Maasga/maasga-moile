class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://maasga-website.pages.dev',
  );

  /// Client OAuth « Web » (client_type 3) du projet Firebase `maasga-83b35`
  /// (project_number 80812184966).
  ///
  /// Sert de `clientId` sur Web et de `serverClientId` sur Android — Google
  /// exige le client *Web* dans les deux cas, jamais le client Android.
  ///
  /// Doit rester aligné sur `android/app/google-services.json` → `oauth_client`.
  /// Un seul identifiant pour toute l'app : ne pas redéclarer ailleurs.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '80812184966-rqc9o2sj4n4fa0a9jba1kcnmg2fubsam.apps.googleusercontent.com',
  );

  /// Version affichée dans les réglages.
  ///
  /// `package_info_plus` lirait la vraie valeur du build, mais ajouter cette
  /// dépendance suppose un `flutter pub get` : en attendant, cette constante
  /// doit rester alignée sur `version:` de `pubspec.yaml`, ou être fournie au
  /// build via `--dart-define=APP_VERSION=...`.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}

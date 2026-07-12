# Règles ProGuard/R8 — PRÊTES mais NON activées par défaut.
#
# Pour activer la minification/obfuscation en release, décommenter le bloc
# `isMinifyEnabled` dans android/app/build.gradle.kts, PUIS tester un vrai
# build release sur appareil (la réflexion de Firebase/webview/pdf peut casser
# sans ces règles). Ne pas activer sans QA d'un build release signé.

# --- Flutter ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase / Messaging ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- WebView (webview_flutter) : garder les interfaces JS ---
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# --- PDF / printing (peut utiliser la réflexion / classes natives) ---
-dontwarn com.shockwave.**
-keep class com.shockwave.** { *; }

# --- Modèles sérialisés (adapter si ajout de json_serializable/Gson) ---
# -keep class com.maasga.app.models.** { *; }

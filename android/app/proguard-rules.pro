# Règles ProGuard/R8 — ACTIVES.
#
# `isMinifyEnabled = true` et `isShrinkResources = true` sont posés dans
# android/app/build.gradle.kts (buildTypes.release). Ce fichier est donc
# appliqué à chaque build release : toute règle retirée ici peut casser la
# réflexion de Firebase / PDF / Riverpod à l'exécution — et uniquement en
# release. Tester sur appareil après toute modification.

# --- Flutter ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase / Messaging ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Interfaces JS d'une éventuelle WebView (flutter_inappwebview, plugins
#     tiers). webview_flutter n'est plus une dépendance directe. ---
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# --- PDF / printing (peut utiliser la réflexion / classes natives) ---
-dontwarn com.shockwave.**
-keep class com.shockwave.** { *; }

# --- Modèles sérialisés (adapter si ajout de json_serializable/Gson) ---
# -keep class com.maasga.app.models.** { *; }

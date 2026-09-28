# Guide du keystore de publication — MAASGA Mobile

## État actuel

Le keystore de publication a été généré le **6 septembre 2026** et est stocké dans :

```
C:\Users\sayta\maasga-upload.jks
```

Le fichier `android/key.properties` pointe vers ce keystore. Il est exclu du
versioning par `android/.gitignore`. **Ne pas committer ce fichier.**

### Empreintes du certificat de signature

```
Alias      : upload
SHA-1      : 54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B
SHA-256    : B3:9F:69:5A:65:D5:BF:D2:DC:42:9D:8C:9B:14:26:55:CA:0D:8B:C8:2E:8E:EA:1F:B1:02:67:59:01:C9:51:F4
Validité   : 10 000 jours (~27 ans)
Algorithme : RSA 2048 bits / SHA384withRSA
```

> **Action requise — Google Cloud Console** : restreindre la clé Google Maps
> (`AIzaSyCk_jfEfhaVbdloYN12DEgbrBXPyZqorlY`) au package `com.maasga.app`
> avec le SHA-1 ci-dessus. Voir la section "Restriction de la clé Maps" plus bas.

---

## Générer un builds de publication

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
# Sortie : build/app/outputs/bundle/release/app-release.aab
```

### APK universel (distribution directe)
```bash
flutter build apk --release
# Sortie : build/app/outputs/flutter-apk/app-release.apk (~68 Mo)
```

### APK split par ABI (~25 Mo chacun, recommandé hors Play Store)
```bash
flutter build apk --release --split-per-abi
# Sorties :
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   ← téléphones récents
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← appareils anciens
#   build/app/outputs/flutter-apk/app-x86_64-release.apk      ← émulateurs uniquement
```

---

## Restriction de la clé Google Maps dans GCP

1. Aller sur [console.cloud.google.com](https://console.cloud.google.com)
2. APIs & Services → Credentials → cliquer sur la clé `AIzaSyA7...`
3. Sous **Application restrictions** → sélectionner **Android apps**
4. Ajouter une entrée :
   - Package name : `com.maasga.app`
   - SHA-1 : `54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B`
5. Sous **API restrictions** → restreindre à **Maps SDK for Android**
6. Sauvegarder

---

## Recréer le keystore (si perdu)

```bash
keytool -genkey -v \
  -keystore ~/maasga-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass "maasga2025!" \
  -keypass "maasga2025!" \
  -dname "CN=MAASGA, OU=Mobile, O=MAASGA SARL, L=Ouagadougou, ST=Centre, C=BF"
```

Puis mettre à jour `android/key.properties` :

```properties
storePassword=maasga2025!
keyPassword=maasga2025!
keyAlias=upload
storeFile=C:/Users/<utilisateur>/maasga-upload.jks
```

> ⚠️ Si l'app est déjà publiée sur le Play Store, **ne jamais regénérer le
> keystore** — Google lie les mises à jour à la clé de signature initiale.
> En cas de perte, contacter le support Google Play pour la récupération via
> Play App Signing.

---

## Bonnes pratiques

- Ne jamais committer `key.properties`, `*.jks`, `*.keystore`
- Sauvegarder `maasga-upload.jks` + les mots de passe dans un gestionnaire
  de mots de passe sécurisé (Bitwarden, 1Password…)
- Utiliser `MAASGA_ALLOW_DEBUG_SIGNING=true` uniquement en CI jetable
- Ne jamais distribuer un APK signé debug (clé publique SDK Android)

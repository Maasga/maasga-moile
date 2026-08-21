import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinVersion
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") version "2.3.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Chargement de la config de signature release depuis android/key.properties
// (fichier NON versionné).
//
// Sans keystore, la build release ÉCHOUE volontairement. L'ancien comportement
// retombait en silence sur la clé debug : un `flutter build apk --release`
// produisait alors un APK signé debug — refusé par le Play Store, et surtout
// installable par-dessus n'importe quelle app signée avec la clé debug
// publique du SDK. Pour un build jetable (CI, test de compilation), poser
// explicitement MAASGA_ALLOW_DEBUG_SIGNING=true.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val allowDebugSigning = System.getenv("MAASGA_ALLOW_DEBUG_SIGNING") == "true"

android {
    namespace = "com.maasga.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "com.maasga.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else if (allowDebugSigning) {
                logger.warn(
                    "⚠️  MAASGA : build RELEASE signée avec la clé DEBUG " +
                        "(android/key.properties absent). Artefact de test " +
                        "uniquement — NE PAS distribuer."
                )
                signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Build release impossible : android/key.properties est absent.\n" +
                        "  • Pour publier : créer key.properties " +
                        "(storeFile / storePassword / keyAlias / keyPassword).\n" +
                        "  • Pour un build jetable : " +
                        "MAASGA_ALLOW_DEBUG_SIGNING=true flutter build apk --release"
                )
            }

            // Minification/obfuscation R8 activée en release.
            // Les règles proguard-rules.pro protègent Flutter, Firebase,
            // WebView, PDF et les modèles Riverpod/Dio.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    jvmToolchain(21)
    compilerOptions {
        languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_3)
        apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_3)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

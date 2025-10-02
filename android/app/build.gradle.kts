import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ en vez de "kotlin-android"
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Cargar el archivo key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.zonafood.kokoplaza"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        // ✅ Usa Java 17 si tu AGP/Gradle lo requieren
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" // ✅
    }

    defaultConfig {
        applicationId = "com.zonafood.kokoplaza"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Solo crear la config de firma si realmente hay propiedades válidas
    if (keystorePropertiesFile.exists()
        && keystoreProperties.getProperty("keyAlias") != null
        && keystoreProperties.getProperty("keyPassword") != null
        && keystoreProperties.getProperty("storeFile") != null
        && keystoreProperties.getProperty("storePassword") != null
    ) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // Si tu .jks está en android/, deja solo el nombre del archivo en key.properties
                // (p.ej. storeFile=my-release-key.jks)
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            // ✅ No revientes si no hay release signing:
            signingConfig = signingConfigs.findByName("release")
        }
        // (opcional) asegura debug:
        getByName("debug") {
            signingConfig = signingConfigs.findByName("debug") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ⚠️ Normalmente el classpath de google-services va en el build.gradle raíz.
// Si ya lo tienes allí, puedes quitar este bloque buildscript del módulo app.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}

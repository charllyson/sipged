plugins {
    id("com.android.application")
    id("kotlin-android")

    // Processa o google-services.json deste módulo Android.
    id("com.google.gms.google-services")

    // O plugin Flutter deve permanecer depois dos plugins Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Mantido nesta etapa para não mover ou renomear a MainActivity.
    namespace = "sisgeo.charllyson.sisgeo"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Deve corresponder ao app Android cadastrado no Firebase.
        applicationId = "com.charllyson.sisgeo"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Configuração temporária já existente.
            // A assinatura release será tratada separadamente no F09.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
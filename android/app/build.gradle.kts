import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Load keystore properties ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key-dev.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val prodKeystoreProperties = Properties()
val prodKeystorePropertiesFile = rootProject.file("key-prod.properties")
if (prodKeystorePropertiesFile.exists()) {
    prodKeystoreProperties.load(FileInputStream(prodKeystorePropertiesFile))
}

android {
    namespace = "com.example.niche_interest_matchmaker_app"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.niche_interest_matchmaker_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("dev_config") {
            if (System.getenv("DEV_KEY_ALIAS") != null) { // Chạy trên GitHub Actions nhánh Dev
                keyAlias = System.getenv("DEV_KEY_ALIAS")
                keyPassword = System.getenv("DEV_KEY_PASSWORD")
                storePassword = System.getenv("DEV_STORE_PASSWORD")
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "dev-keystore.jks")
            } else if (keystorePropertiesFile.exists()) { // Chạy dưới máy Local
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
            }
        }

        create("prod_config") {
            if (System.getenv("KEY_ALIAS") != null) { // Chạy trên GitHub Actions nhánh Main
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
                storePassword = System.getenv("STORE_PASSWORD")
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "release-keystore.jks")
            } else if (prodKeystoreProperties.exists()) { // Chạy dưới máy Local
                keyAlias = prodKeystoreProperties["keyAlias"] as String
                keyPassword = prodKeystoreProperties["keyPassword"] as String
                storePassword = prodKeystoreProperties["storePassword"] as String
                storeFile = file(prodKeystoreProperties["storeFile"] as String)
            }
        }
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            // Tùy chọn: Thêm hậu tố ".dev" vào mã gói ứng dụng
            // App của bạn sẽ thành com.example...app.dev (Giúp cài 2 app cùng lúc trên máy)
            applicationIdSuffix = ".dev" 
            signingConfig = signingConfigs.getByName("dev_config")
        }
        create("prod") {
            dimension = "env"
            signingConfig = signingConfigs.getByName("prod_config")
        }
    }

    buildTypes {
        release {
            
        }
    }
}

flutter {
    source = "../.."
}

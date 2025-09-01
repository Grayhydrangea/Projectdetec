// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ✅ เปิด desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    defaultConfig {
        applicationId = "com.example.frontend"
        // ✅ อย่างน้อย 21 สำหรับ desugaring (คุณตั้งไว้ 23 แล้วโอเค)
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

dependencies {
    // ✅ ไลบรารี desugaring (เลือกเวอร์ชันเสถียร)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // หรือจะใช้ใหม่กว่านี้ก็ได้ เช่น 2.1.2:
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")

    // รองรับ Material/AppCompat ที่ธีมใช้อยู่
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.10.0")
}

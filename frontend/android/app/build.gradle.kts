plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // ใช้ id ทางการสำหรับ Kotlin Android ใน KTS
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.frontend"

    // ค่าพวกนี้ Flutter จะป้อนมาให้ แต่เราสามารถ override ได้ตามต้องการ
    compileSdk = flutter.compileSdkVersion

    // NDK: จาก error ก่อนหน้า cloud_firestore / firebase_core ต้องการ 27.x
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.frontend"

        // ✅ แก้ประเด็นหลัก: บังคับอย่างน้อย 23 (หากค่า Flutter ต่ำกว่า)
        minSdk = maxOf(23, flutter.minSdkVersion)

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ใช้ debug keystore ชั่วคราวเพื่อให้ `flutter run --release` ทำงานได้
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

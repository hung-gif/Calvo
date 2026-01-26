plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calvo"
    // Sử dụng mức SDK 36 để tương thích với các plugin mới nhất
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Bắt buộc bật để hỗ trợ flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.calvo"
        minSdk = flutter.minSdkVersion // Hoặc flutter.minSdkVersion nếu >= 21
        targetSdk = 35 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Kích hoạt MultiDex cho các dự án nhiều thư viện
        multiDexEnabled = true 
    }

    buildTypes {
        getByName("debug") {
            // Ngăn chặn ClassNotFoundException cho dịch vụ thông báo
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            isMinifyEnabled = false 
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Thư viện hỗ trợ các tính năng Java hiện đại trên Android cũ
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

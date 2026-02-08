plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calvo"
    
    compileSdk = 36
    ndkVersion = flutter.ndkVersion


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.calvo"
        minSdk = flutter.minSdkVersion // Hoặc flutter.minSdkVersion nếu >= 21
        targetSdk = 36
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
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isMinifyEnabled = false 
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation(project(":flutter_notification_listener"))
    implementation("androidx.work:work-runtime-ktx:2.8.1")
    implementation("androidx.work:work-runtime:2.8.1")

}


tasks.configureEach {
    if (name == "assembleDebug") {
        finalizedBy("copyDebugApkToFlutterExpectedLocation")
    }
}

tasks.register("copyDebugApkToFlutterExpectedLocation") {
    doLast {
        // Đường dẫn gốc mà Gradle 8.11 đang xuất file
        val debugApkPath = "${project.projectDir}/build/outputs/apk/debug/app-debug.apk"
        
        // Đường dẫn mà Flutter Tool đang đi tìm
        val expectedPath = "${project.rootDir}/../build/app/outputs/flutter-apk/app-debug.apk"
        
        val debugFile = file(debugApkPath)
        val expectedFile = file(expectedPath)

        if (debugFile.exists()) {
            expectedFile.parentFile.mkdirs()
            debugFile.copyTo(expectedFile, overwrite = true)
            println("✅ Đã copy APK thành công sang: $expectedPath")
        } else {
            println("❌ Không tìm thấy file APK tại: $debugApkPath")
            println("Vui lòng kiểm tra lại cấu hình build của AGP 8.11")
        }
    }
}
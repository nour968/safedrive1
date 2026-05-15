plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.example.untitled1"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {

        applicationId = "com.example.untitled1"

        minSdk = flutter.minSdkVersion
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

flutter {
    source = "../.."
}

dependencies {

    // SOCKET.IO
    implementation("io.socket:socket.io-client:2.1.0") {
        exclude(group = "org.json", module = "json")
    }

    // OKHTTP
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // GSON
    implementation("com.google.code.gson:gson:2.10.1")

    // CAMERA X
    val cameraxVersion = "1.3.0"

    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
    implementation("androidx.camera:camera-view:$cameraxVersion")
    implementation("androidx.camera:camera-video:$cameraxVersion")

    // APP COMPAT
    implementation("androidx.appcompat:appcompat:1.6.1")

    // CORE
    implementation("androidx.core:core:1.12.0")

    // LIFECYCLE
    implementation("androidx.lifecycle:lifecycle-runtime:2.7.0")

    // GUAVA
    implementation("com.google.guava:guava:31.1-android")
}

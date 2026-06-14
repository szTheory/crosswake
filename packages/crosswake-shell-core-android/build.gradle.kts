plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("kotlinx-serialization")
    id("com.vanniktech.maven.publish") version "0.31.0"
}

version = "0.1.0" // x-release-please-version

android {
    namespace = "dev.crosswake.shell.core"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    // Note: Android bridge may use WebKit/WebView and we might need androidx.webkit
    implementation("androidx.webkit:webkit:1.10.0")
}

mavenPublishing {
    publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = false)
    signAllPublications()

    coordinates("io.github.sztheory", "crosswake-shell-core-android", version.toString())

    pom {
        name.set("Crosswake Shell Core Android")
        description.set("Android native shell core for the Crosswake Phoenix library.")
        inceptionYear.set("2024")
        url.set("https://github.com/szTheory/crosswake")

        licenses {
            license {
                name.set("MIT License")
                url.set("https://opensource.org/licenses/MIT")
                distribution.set("https://opensource.org/licenses/MIT")
            }
        }

        developers {
            developer {
                id.set("szTheory")
                name.set("szTheory")
                url.set("https://github.com/szTheory/")
            }
        }

        scm {
            url.set("https://github.com/szTheory/crosswake/")
            connection.set("scm:git:git://github.com/szTheory/crosswake.git")
            developerConnection.set("scm:git:ssh://git@github.com/szTheory/crosswake.git")
        }
    }
}

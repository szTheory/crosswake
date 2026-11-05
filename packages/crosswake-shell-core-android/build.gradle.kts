import com.vanniktech.maven.publish.SonatypeHost

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("com.vanniktech.maven.publish") version "0.31.0"
}

version = "0.2.11" // x-release-please-version

// A fire-drill may exercise the signed Portal upload with an invocation-owned coordinate.
// Release Please still owns the literal above; the override never changes the checked-in version.
(findProperty("crosswakeVersion") as String?)?.let { version = it }

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
    // Imported by BridgeChannel.kt (WebViewCompat.addWebMessageListener).
    implementation("androidx.webkit:webkit:1.10.0")

    testImplementation("junit:junit:4.13.2")
    // AOSP-derived org.json for JVM unit tests (Phase 198 D-09). Android's android.jar stubs
    // org.json as "not mocked", so tests need a real implementation. This artifact is used
    // instead of the Crockford org.json build because it coerces like the platform library
    // (getString on numbers and JSON null) while the Crockford build is stricter, so a
    // "non-string rejected" test cannot pass only because the JVM library is stricter.
    // Production uses the platform org.json with no runtime dependency. JVM evidence only,
    // not device evidence; decision recorded in 198-DECISIONS.md.
    testImplementation("com.vaadin.external.google:android-json:0.0.20131108.vaadin1")
}

mavenPublishing {
    // Default false: upload stops at VALIDATED so the fire-drill can validate then
    // DROP without consuming the coordinate. The real release job opts in with
    // -PcrosswakeAutomaticRelease=true so the deployment auto-publishes to Maven
    // Central once validated (no manual Portal click, lets clean-room-proof resolve it).
    val automaticRelease =
        (project.findProperty("crosswakeAutomaticRelease") as String?)?.toBoolean() ?: false
    publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = automaticRelease)
    // Signing is required for the real Maven Central publish (default). CI's hermetic
    // `publishToMavenLocal` (used so a version-bump release PR can resolve the not-yet-
    // published shell-core from ~/.m2) has no signing keys, so it opts out with
    // -PcrosswakeSkipSigning=true. Local publish is never uploaded, so it needs no signature.
    val skipSigning =
        (project.findProperty("crosswakeSkipSigning") as String?)?.toBoolean() ?: false
    if (!skipSigning) {
        signAllPublications()
    }

    coordinates("io.github.sztheory", "crosswake-shell-core-android", version.toString())

    pom {
        name.set("Crosswake Shell Core Android")
        description.set("Android native shell core for the Crosswake Phoenix library.")
        inceptionYear.set("2024")
        url.set("https://github.com/szTheory/crosswake")

        licenses {
            license {
                name.set("The Apache License, Version 2.0")
                url.set("https://www.apache.org/licenses/LICENSE-2.0.txt")
                distribution.set("repo")
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

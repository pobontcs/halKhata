// android/build.gradle.kts

plugins {
    // 1. Android Application Plugin (Keep version here)
    id("com.android.application") version "8.11.1" apply false

    // 2. Android Library Plugin (REMOVE version here to fix the crash)
    id("com.android.library") apply false

    // 3. Kotlin Plugin
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false

    // 4. Google Services (Firebase) Plugin
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Latest stable Google Services plugin for Flutter
        classpath("com.google.gms:google-services:4.4.0")
        // Android Gradle plugin (keep your current version)
        classpath("com.android.tools.build:gradle:8.2.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: custom build directories
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
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

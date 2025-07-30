buildscript {
    repositories {
        google()  // Make sure Google Maven repository is included
        mavenCentral()
    }
    dependencies {
        // Add the Google services classpath for Firebase
        classpath("com.google.gms:google-services:4.3.10")  // Ensure this is in the buildscript block
    }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

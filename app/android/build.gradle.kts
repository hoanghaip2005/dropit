allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// firebase_messaging 16.0.0 imports these directly but relies on transitive
// dependencies that are absent with the current Firebase Android SDK.
subprojects {
    if (name == "firebase_messaging") {
        plugins.withId("com.android.library") {
            dependencies.add("implementation", "androidx.core:core:1.13.1")
            dependencies.add("implementation", "androidx.lifecycle:lifecycle-livedata:2.8.7")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

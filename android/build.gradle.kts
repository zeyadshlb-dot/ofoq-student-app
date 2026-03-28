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
    project.plugins.withId("com.android.library") {
        project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java).apply {
            if (namespace == null) {
                namespace = "com.ofoq.plugins.${project.name.replace("-", "_")}"
            }
        }
    }
    project.plugins.withId("com.android.application") {
        project.extensions.getByType(com.android.build.gradle.AppExtension::class.java).apply {
            if (namespace == null) {
                namespace = "com.ofoq.plugins.${project.name.replace("-", "_")}"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
